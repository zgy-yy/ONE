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
            // 月份变化时由 View 决定滚到已有分区或 force 重载
        }
    }

    /// 排序（文章 / 系列共用）。
    var listSort: ArticleSort = .publishedAt {
        didSet {
            guard oldValue != listSort else { return }
            articleFeeds = [:]
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

    /// 文章列表缓存 key（供 View `.task(id:)` 使用）；月份不参与，避免切换日期取消任务。
    var articleListTaskKey: String {
        listSort.rawValue
    }

    /// 系列列表缓存 key。
    var seriesFeedKey: String {
        "\(seriesStatus.rawValue)-\(listSort.rawValue)"
    }

    private var articleFeeds: [ContentCategory: MonthPagedFeed] = [:]
    private var articlePullRefreshing: Set<ContentCategory> = []
    private var seriesFeeds: [String: PagedListState<SeriesSummary>] = [:]
    private let pageSize = 20

    private init() {}

    // MARK: - 文章（按月串联）

    func articleSections(for channel: ContentCategory) -> [ArticleMonthSection] {
        articleFeeds[channel]?.sections ?? []
    }

    func articleError(for channel: ContentCategory) -> String? {
        articleFeeds[channel]?.error
    }

    func isLoadingArticles(_ channel: ContentCategory) -> Bool {
        articlePullRefreshing.contains(channel) || articleFeeds[channel]?.isLoading == true
    }

    func pullToRefreshArticles(channel: ContentCategory) async {
        articlePullRefreshing.insert(channel)
        await Task.detached { @MainActor in
            defer { DiscoverSession.shared.articlePullRefreshing.remove(channel) }
            await DiscoverSession.shared.loadArticles(channel: channel, force: true)
        }.value
    }

    func isLoadingMoreArticles(_ channel: ContentCategory) -> Bool {
        articleFeeds[channel]?.isLoadingMore == true
    }

    func showsArticlesEndFooter(_ channel: ContentCategory) -> Bool {
        articleFeeds[channel]?.showsEndFooter == true
    }

    func loadArticles(channel: ContentCategory, force: Bool = false) async {
        guard let modelID = channel.articleModelID else { return }
        let feed = articleFeed(for: channel)
        let sort = listSort.rawValue
        let size = pageSize
        await feed.runLoad(force: force, anchorMonth: listPublishedAt) { month, page, _ in
            try await OneClient.articleDiscovery(
                modelID: modelID,
                publishedAt: month,
                sort: sort,
                page: page,
                size: size
            )
        }
    }

    func loadMoreArticles(channel: ContentCategory) async {
        guard let modelID = channel.articleModelID else { return }
        guard let feed = articleFeeds[channel] else { return }
        let sort = listSort.rawValue
        let size = pageSize
        await feed.runLoadMore { month, page, _ in
            try await OneClient.articleDiscovery(
                modelID: modelID,
                publishedAt: month,
                sort: sort,
                page: page,
                size: size
            )
        }
    }

    private func articleFeed(for channel: ContentCategory) -> MonthPagedFeed {
        if let feed = articleFeeds[channel] { return feed }
        let feed = MonthPagedFeed(pageSize: pageSize)
        articleFeeds[channel] = feed
        return feed
    }

    // MARK: - 系列

    func series(for channel: ContentCategory) -> [SeriesSummary] {
        seriesFeeds[seriesKey(channel)]?.items ?? []
    }

    func seriesError(for channel: ContentCategory) -> String? {
        seriesFeeds[seriesKey(channel)]?.error
    }

    func isLoadingSeries(_ channel: ContentCategory) -> Bool {
        seriesFeeds[seriesKey(channel)]?.isLoading == true
    }

    func isLoadingMoreSeries(_ channel: ContentCategory) -> Bool {
        seriesFeeds[seriesKey(channel)]?.isLoadingMore == true
    }

    func showsSeriesEndFooter(_ channel: ContentCategory) -> Bool {
        let feed = seriesFeeds[seriesKey(channel)]
        return feed?.loaded == true && feed?.exhausted == true
    }

    func loadSeries(channel: ContentCategory, force: Bool = false) async {
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
            feed.failLoad(error)
            seriesFeeds[key] = feed
        }
    }

    func loadMoreSeries(channel: ContentCategory) async {
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

    // MARK: - 系列网络

    private func fetchSeries(channel: ContentCategory, page: Int) async throws -> [SeriesSummary] {
        switch channel {
        case .album:
            return try await OneClient.seriesAlbumList(
                type: seriesStatus.rawValue,
                page: page,
                size: pageSize,
                sort: listSort.rawValue
            )
        case .manga:
            return try await OneClient.seriesMangaList(
                type: seriesStatus.rawValue,
                page: page,
                size: pageSize,
                sort: listSort.rawValue
            )
        default:
            return []
        }
    }

    private func seriesKey(_ channel: ContentCategory) -> String {
        "\(channel.rawValue)|\(seriesFeedKey)"
    }
}
