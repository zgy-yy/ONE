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

    /// 供 `.task(id:)`：仅排序变化需整表重载；月份由列表滚动或 force 锚定。
    var articleListTaskKey: String {
        listSort.rawValue
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
        let sort = listSort.rawValue
        let size = articlePageSize
        await feed.runLoad(
            force: force,
            anchorMonth: listPublishedAt,
            publish: { articleFeeds[tagID] = $0 }
        ) { month, page, _ in
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
        guard var feed = articleFeeds[tagID] else { return }
        let sort = listSort.rawValue
        let size = articlePageSize
        await feed.runLoadMore(publish: { articleFeeds[tagID] = $0 }) { month, page, _ in
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
}
