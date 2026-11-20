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

    private var articleFeeds: [Int: MonthPagedFeed] = [:]
    /// 下拉刷新中：`refreshable` 被取消后仍需保持整页 loading，直到 detached 内 `loadArticles` 结束。
    private var articlePullRefreshing: Set<Int> = []
    private let articlePageSize = 20
    /// 顶栏锚定/跳转月份；已有分区时由列表滚动，否则重载。
    var listPublishedAt: String = MonthYear.now.apiString

    var listSort: ArticleSort = .publishedAt {
        didSet {
            guard oldValue != listSort else { return }
            articleFeeds = [:]
        }
    }

    /// 供 `.task(id:)`：仅排序变化需整表重载；月份由列表滚动或 force 锚定。
    var articleListTaskKey: String {
        listSort.rawValue
    }



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
        articlePullRefreshing.contains(tagID) || articleFeeds[tagID]?.isLoading == true
    }

    func isLoadingMoreArticles(tagID: Int) -> Bool {
        articleFeeds[tagID]?.isLoadingMore == true
    }

    func showsArticlesEndFooter(tagID: Int) -> Bool {
        articleFeeds[tagID]?.showsEndFooter == true
    }

    func pullToRefreshArticles(for tagID: Int) async {
        articlePullRefreshing.insert(tagID)
        await Task.detached { @MainActor in
            defer { VodSession.shared.articlePullRefreshing.remove(tagID) }
            await VodSession.shared.loadArticles(for: tagID, force: true)
        }.value
    }

    func loadArticles(for tagID: Int, force: Bool = false) async {
        let feed = articleFeed(for: tagID)
        let sort = listSort.rawValue
        let size = articlePageSize
        await feed.runLoad(force: force, anchorMonth: listPublishedAt) { month, page, _ in
            try await OneClient.articleDiscovery(
                modelID: ContentCategory.ModelID.vod,
                publishedAt: month,
                sort: sort,
                page: page,
                size: size,
                demandTagID: tagID
            )
        }
    }

    func loadMoreArticles(for tagID: Int) async {
        guard let feed = articleFeeds[tagID] else { return }
        let sort = listSort.rawValue
        let size = articlePageSize
        await feed.runLoadMore { month, page, _ in
            try await OneClient.articleDiscovery(
                modelID: ContentCategory.ModelID.vod,
                publishedAt: month,
                sort: sort,
                page: page,
                size: size,
                demandTagID: tagID
            )
        }
    }

    private func articleFeed(for tagID: Int) -> MonthPagedFeed {
        if let feed = articleFeeds[tagID] { return feed }
        let feed = MonthPagedFeed(pageSize: articlePageSize)
        articleFeeds[tagID] = feed
        return feed
    }
}
