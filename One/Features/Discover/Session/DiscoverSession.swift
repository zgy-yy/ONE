import Foundation
import Observation

/// 发现页数据：文章频道按月串联；写真 / 漫画系列仍扁平分页。
@MainActor
@Observable
final class DiscoverSession {
    static let shared = DiscoverSession()

    /// 文章频道的锚定月份（顶栏筛选；下滑会继续拉更早月）。
    var listPublishedAt: String = MonthYear.now.apiString {
        didSet {
            guard oldValue != listPublishedAt else { return }
            // 月份变化时由 View 决定滚到已有分区或 force 重载，这里只清 loading 标记外的缓存键语义
        }
    }

    /// 排序（文章 / 系列共用）。
    var listSort: VodArticleSort = .publishedAt {
        didSet {
            guard oldValue != listSort else { return }
            channelArticles = [:]
            seriesFeeds = [:]
        }
    }

    /// 系列连载状态筛选。
    var seriesStatus: SeriesStatusType = .all {
        didSet {
            guard oldValue != seriesStatus else { return }
            seriesFeeds = [:]
        }
    }

    /// 文章列表缓存 key（供 View `.task(id:)` 使用）。
    var articleFeedKey: String {
        "\(listPublishedAt)-\(listSort.rawValue)"
    }

    /// 系列列表缓存 key。
    var seriesFeedKey: String {
        "\(seriesStatus.rawValue)-\(listSort.rawValue)"
    }

    private var channelArticles: [DiscoverChannel: TagsArticles] = [:]
    private var articlesLoading: Set<DiscoverChannel> = []
    private var articlesLoadingMore: Set<DiscoverChannel> = []

    private var seriesFeeds: [String: PagedListState<SeriesSummary>] = [:]
    private let pageSize = 20

    private init() {}

    // MARK: - 文章（按月串联）

    func articleSections(for channel: DiscoverChannel) -> [ArticleMonthSection] {
        channelArticles[channel]?.sections ?? []
    }

    func articleError(for channel: DiscoverChannel) -> String? {
        channelArticles[channel]?.error
    }

    func isLoadingArticles(_ channel: DiscoverChannel) -> Bool {
        articlesLoading.contains(channel)
    }

    func isLoadingMoreArticles(_ channel: DiscoverChannel) -> Bool {
        articlesLoadingMore.contains(channel)
    }

    func showsArticlesEndFooter(_ channel: DiscoverChannel) -> Bool {
        guard let state = channelArticles[channel], state.loaded else { return false }
        return state.fullyExhausted
    }

    func loadArticles(channel: DiscoverChannel, force: Bool = false) async {
        guard channel.articleModelID != nil else { return }
        if force { channelArticles[channel] = nil }
        guard !articlesLoading.contains(channel), channelArticles[channel]?.loaded != true else { return }

        articlesLoading.insert(channel)
        defer { articlesLoading.remove(channel) }

        var state = TagsArticles()
        state.reset()
        channelArticles[channel] = state

        await fetchArticlePage(channel: channel, month: listPublishedAt, page: 1, newSection: true)
        await advancePastEmptyMonths(channel: channel)
        markFullyExhaustedIfNeeded(channel: channel)
    }

    func loadMoreArticles(channel: DiscoverChannel) async {
        guard channel.articleModelID != nil else { return }
        guard let state = channelArticles[channel], state.loaded, state.canLoadMore else { return }
        guard !articlesLoading.contains(channel), !articlesLoadingMore.contains(channel) else { return }
        guard let next = state.nextPageRequest else {
            markFullyExhaustedIfNeeded(channel: channel)
            return
        }

        articlesLoadingMore.insert(channel)
        defer { articlesLoadingMore.remove(channel) }

        await fetchArticlePage(
            channel: channel,
            month: next.month,
            page: next.page,
            newSection: next.newSection
        )
        markFullyExhaustedIfNeeded(channel: channel)
    }

    // MARK: - 系列

    func series(for channel: DiscoverChannel) -> [SeriesSummary] {
        seriesFeeds[seriesKey(channel)]?.items ?? []
    }

    func seriesError(for channel: DiscoverChannel) -> String? {
        seriesFeeds[seriesKey(channel)]?.error
    }

    func isLoadingSeries(_ channel: DiscoverChannel) -> Bool {
        seriesFeeds[seriesKey(channel)]?.isLoading == true
    }

    func isLoadingMoreSeries(_ channel: DiscoverChannel) -> Bool {
        seriesFeeds[seriesKey(channel)]?.isLoadingMore == true
    }

    func showsSeriesEndFooter(_ channel: DiscoverChannel) -> Bool {
        let feed = seriesFeeds[seriesKey(channel)]
        return feed?.loaded == true && feed?.exhausted == true
    }

    func loadSeries(channel: DiscoverChannel, force: Bool = false) async {
        guard channel.isSeries else { return }
        let key = seriesKey(channel)
        var feed = seriesFeeds[key] ?? PagedListState(pageSize: pageSize)
        guard feed.beginLoad(force: force) else {
            seriesFeeds[key] = feed
            return
        }
        seriesFeeds[key] = feed

        do {
            feed.finishLoad(try await fetchSeries(channel: channel, page: 1))
            seriesFeeds[key] = feed
        } catch {
            feed.failLoad(error.localizedDescription)
            seriesFeeds[key] = feed
        }
    }

    func loadMoreSeries(channel: DiscoverChannel) async {
        guard channel.isSeries else { return }
        let key = seriesKey(channel)
        guard var feed = seriesFeeds[key], let page = feed.beginLoadMore() else { return }
        seriesFeeds[key] = feed

        do {
            feed.finishLoadMore(try await fetchSeries(channel: channel, page: page))
            seriesFeeds[key] = feed
        } catch {
            feed.cancelLoadMore()
            seriesFeeds[key] = feed
        }
    }

    // MARK: - 文章分页

    private func advancePastEmptyMonths(channel: DiscoverChannel) async {
        while channelArticles[channel]?.shouldAdvancePastEmptyTail == true {
            guard let next = channelArticles[channel]?.nextPageRequest else { break }
            await fetchArticlePage(
                channel: channel,
                month: next.month,
                page: next.page,
                newSection: next.newSection
            )
        }
    }

    private func markFullyExhaustedIfNeeded(channel: DiscoverChannel) {
        guard var state = channelArticles[channel] else { return }
        state.markFullyExhaustedIfNeeded()
        channelArticles[channel] = state
    }

    private func fetchArticlePage(
        channel: DiscoverChannel,
        month: String,
        page: Int,
        newSection: Bool
    ) async {
        guard let modelID = channel.articleModelID else { return }
        guard let creds = OneCredentials.pair(tokenPath: OneAPI.discoveryPath) else {
            if page == 1, newSection {
                setArticleError(OneCredentials.readinessError, for: channel)
            }
            return
        }

        do {
            let list = try await OneClient.articleDiscovery(
                base: creds.base,
                token: creds.token,
                request: .discoverList(
                    modelID: modelID,
                    publishedAt: month,
                    sort: listSort.rawValue,
                    page: page,
                    size: pageSize
                )
            )
            var state = channelArticles[channel, default: TagsArticles()]
            state.mergePage(
                month: month,
                list: list,
                page: page,
                pageSize: pageSize,
                newSection: newSection
            )
            channelArticles[channel] = state
        } catch {
            if page == 1, newSection {
                setArticleError(error.localizedDescription, for: channel)
            }
        }
    }

    private func setArticleError(_ message: String, for channel: DiscoverChannel) {
        var state = channelArticles[channel, default: TagsArticles()]
        state.recordError(message)
        channelArticles[channel] = state
    }

    // MARK: - 系列网络

    private func fetchSeries(channel: DiscoverChannel, page: Int) async throws -> [SeriesSummary] {
        guard let path = channel.seriesListPath else { return [] }
        guard let creds = OneCredentials.pair(tokenPath: path) else {
            throw OneClientError.apiRejected(OneCredentials.readinessError)
        }

        switch channel {
        case .album:
            return try await OneClient.seriesAlbumList(
                base: creds.base,
                token: creds.token,
                type: seriesStatus.rawValue,
                page: page,
                size: pageSize,
                sort: listSort.rawValue
            )
        case .manga:
            return try await OneClient.seriesMangaList(
                base: creds.base,
                token: creds.token,
                type: seriesStatus.rawValue,
                page: page,
                size: pageSize,
                sort: listSort.rawValue
            )
        default:
            return []
        }
    }

    private func seriesKey(_ channel: DiscoverChannel) -> String {
        "\(channel.rawValue)|\(seriesFeedKey)"
    }
}
