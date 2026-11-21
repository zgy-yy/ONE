import Foundation
import Observation

/// 点击首页日期后：`article/discovery`（图文），按月分段并向下加载更早月份。
@MainActor
@Observable
final class HomeMonthSession {
    let anchorMonth: String

    private var feed = MonthPagedFeed(pageSize: 20)
    private(set) var isPullRefreshing = false

    init(monthAPIString: String) {
        self.anchorMonth = monthAPIString
    }

    var sections: [ArticleMonthSection] { feed.sections }
    var isLoading: Bool { isPullRefreshing || feed.isLoading }
    var isLoadingMore: Bool { feed.isLoadingMore }
    var error: String? { feed.error }
    var loaded: Bool { feed.loaded }
    var fullyExhausted: Bool { feed.fullyExhausted }
    var canLoadMore: Bool { feed.canLoadMore }
    var showsLoadMoreEnd: Bool { feed.showsEndFooter }

    var hasContent: Bool {
        !sections.isEmpty && sections.contains { !$0.articles.isEmpty }
    }

    func pullToRefresh() async {
        isPullRefreshing = true
        await Task.detached { @MainActor in
            defer { self.isPullRefreshing = false }
            await self.load(force: true)
        }.value
    }

    func load(force: Bool = false) async {
        await feed.runLoad(force: force, anchorMonth: anchorMonth) { month, page, _ in
            try await OneClient.articleDiscovery(
                modelID: ContentCategory.ModelID.graphic,
                publishedAt: month,
                sort: ArticleSort.publishedAt.rawValue,
                page: page,
                size: 20
            )
        }
    }

    func loadMore() async {
        await feed.runLoadMore { month, page, _ in
            try await OneClient.articleDiscovery(
                modelID: ContentCategory.ModelID.graphic,
                publishedAt: month,
                sort: ArticleSort.publishedAt.rawValue,
                page: page,
                size: 20
            )
        }
    }

    /// 触底时连续拉取，直到当月翻完或暂时没有下一页（避免误显「底线」后需再滑一下）。
    func loadMoreFromSentinel(maxRounds: Int = 8) async {
        var rounds = 0
        while canLoadMore, rounds < maxRounds {
            await loadMore()
            rounds += 1
        }
    }
}
