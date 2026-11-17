import Foundation
import Observation

/// 点播（On-demand）模块状态。
@MainActor
@Observable
final class VodSession {
    static let shared = VodSession()

    private(set) var tags: [DemandTag] = []
    private(set) var isLoading = false
    private(set) var lastError: String?

    /// 顶栏锚定/跳转月份；已有分区时由列表滚动，否则重载。
    var listPublishedAt: String = MonthYear.now.apiString

    var listSort: ArticleSort = .publishedAt {
        didSet {
            guard oldValue != listSort else { return }
            articleFeeds = [:]
        }
    }

    var articleFeedKey: String {
        "\(listPublishedAt)-\(listSort.rawValue)"
    }

    private var articleFeeds: [Int: MonthPagedFeed] = [:]
    private let articlePageSize = 20

    private init() {}

    // MARK: - 分类

    func loadIfNeeded() async {
        guard tags.isEmpty, !isLoading else { return }
        await refresh()
    }

    /// 顶栏分类只拉取一次；已有数据则不再请求。
    func refresh() async {
        guard tags.isEmpty else { return }

        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            let remote = try await OneClient.getDemandTagList()
            tags = [.all] + remote.filter { $0.id != DemandTag.all.id }
            articleFeeds = [:]
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - 文章列表

    func articleSections(for tagID: Int) -> [ArticleMonthSection] {
        articleFeeds[tagID]?.sections ?? []
    }

    func articleError(for tagID: Int) -> String? {
        articleFeeds[tagID]?.error
    }

    func isLoadingArticles(tagID: Int) -> Bool {
        articleFeeds[tagID]?.isLoading == true
    }

    func isLoadingMoreArticles(tagID: Int) -> Bool {
        articleFeeds[tagID]?.isLoadingMore == true
    }

    func showsArticlesEndFooter(tagID: Int) -> Bool {
        articleFeeds[tagID]?.showsEndFooter == true
    }

    func loadArticles(for tagID: Int, force: Bool = false) async {
        var feed = articleFeeds[tagID] ?? MonthPagedFeed(pageSize: articlePageSize)
        guard feed.beginLoad(force: force) else {
            articleFeeds[tagID] = feed
            return
        }
        articleFeeds[tagID] = feed

        let sort = listSort.rawValue
        let size = articlePageSize
        await feed.performLoad(anchorMonth: listPublishedAt) { month, page, _ in
            try await OneClient.articleDiscovery(
                modelID: ContentCategory.ModelID.vod,
                publishedAt: month,
                sort: sort,
                page: page,
                size: size,
                demandTagID: tagID
            )
        }
        articleFeeds[tagID] = feed
    }

    func loadMoreArticles(for tagID: Int) async {
        guard var feed = articleFeeds[tagID] else { return }
        guard feed.beginLoadMore() else {
            articleFeeds[tagID] = feed
            return
        }
        articleFeeds[tagID] = feed

        let sort = listSort.rawValue
        let size = articlePageSize
        await feed.performLoadMore { month, page, _ in
            try await OneClient.articleDiscovery(
                modelID: ContentCategory.ModelID.vod,
                publishedAt: month,
                sort: sort,
                page: page,
                size: size,
                demandTagID: tagID
            )
        }
        articleFeeds[tagID] = feed
    }
}
