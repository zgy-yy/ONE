import Foundation
import Observation

/// 发现页数据：文章频道 + 写真 / 漫画系列。
@MainActor
@Observable
final class DiscoverSession {
    static let shared = DiscoverSession()

    /// 文章频道的月份筛选。
    var listPublishedAt: String = MonthYear.now.apiString {
        didSet {
            guard oldValue != listPublishedAt else { return }
            articleFeeds = [:]
        }
    }

    /// 排序（文章 / 系列共用）。
    var listSort: VodArticleSort = .publishedAt {
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

    /// 文章列表缓存 key（供 View `.task(id:)` 使用）。
    var articleFeedKey: String {
        "\(listPublishedAt)-\(listSort.rawValue)"
    }

    /// 系列列表缓存 key。
    var seriesFeedKey: String {
        "\(seriesStatus.rawValue)-\(listSort.rawValue)"
    }

    private var articleFeeds: [String: PagedListState<ArticleSummary>] = [:]
    private var seriesFeeds: [String: PagedListState<SeriesSummary>] = [:]
    private let pageSize = 20

    private init() {}

    // MARK: - 文章

    func articles(for channel: DiscoverChannel) -> [ArticleSummary] {
        articleFeeds[articleKey(channel)]?.items ?? []
    }

    func articleError(for channel: DiscoverChannel) -> String? {
        articleFeeds[articleKey(channel)]?.error
    }

    func isLoadingArticles(_ channel: DiscoverChannel) -> Bool {
        articleFeeds[articleKey(channel)]?.isLoading == true
    }

    func isLoadingMoreArticles(_ channel: DiscoverChannel) -> Bool {
        articleFeeds[articleKey(channel)]?.isLoadingMore == true
    }

    func showsArticlesEndFooter(_ channel: DiscoverChannel) -> Bool {
        let feed = articleFeeds[articleKey(channel)]
        return feed?.loaded == true && feed?.exhausted == true
    }

    func loadArticles(channel: DiscoverChannel, force: Bool = false) async {
        guard channel.articleModelID != nil else { return }
        let key = articleKey(channel)
        var feed = articleFeeds[key] ?? PagedListState(pageSize: pageSize)
        guard feed.beginLoad(force: force) else {
            articleFeeds[key] = feed
            return
        }
        articleFeeds[key] = feed

        do {
            feed.finishLoad(try await fetchArticles(channel: channel, page: 1))
            articleFeeds[key] = feed
        } catch {
            feed.failLoad(error.localizedDescription)
            articleFeeds[key] = feed
        }
    }

    func loadMoreArticles(channel: DiscoverChannel) async {
        guard channel.articleModelID != nil else { return }
        let key = articleKey(channel)
        guard var feed = articleFeeds[key], let page = feed.beginLoadMore() else { return }
        articleFeeds[key] = feed

        do {
            feed.finishLoadMore(try await fetchArticles(channel: channel, page: page))
            articleFeeds[key] = feed
        } catch {
            feed.cancelLoadMore()
            articleFeeds[key] = feed
        }
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

    // MARK: - 网络请求

    private func fetchArticles(channel: DiscoverChannel, page: Int) async throws -> [ArticleSummary] {
        guard let modelID = channel.articleModelID else { return [] }
        guard let creds = OneCredentials.pair(tokenPath: OneAPI.discoveryPath) else {
            throw OneClientError.apiRejected(OneCredentials.readinessError)
        }
        return try await OneClient.articleDiscovery(
            base: creds.base,
            token: creds.token,
            request: .discoverList(
                modelID: modelID,
                publishedAt: listPublishedAt,
                sort: listSort.rawValue,
                page: page,
                size: pageSize
            )
        )
    }

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

    private func articleKey(_ channel: DiscoverChannel) -> String {
        "\(channel.rawValue)|\(articleFeedKey)"
    }

    private func seriesKey(_ channel: DiscoverChannel) -> String {
        "\(channel.rawValue)|\(seriesFeedKey)"
    }
}
