import Foundation
import Observation

/// 点击首页日期后：`article/discovery`（图文），按月分段并向下加载更早月份。
@MainActor
@Observable
final class HomeMonthSession {
    let anchorMonth: String

    private var feed = MonthPagedFeed(pageSize: 20)

    init(monthAPIString: String) {
        self.anchorMonth = monthAPIString
    }

    var sections: [ArticleMonthSection] { feed.sections }
    var isLoading: Bool { feed.isLoading }
    var isLoadingMore: Bool { feed.isLoadingMore }
    var error: String? { feed.error }
    var loaded: Bool { feed.loaded }
    var fullyExhausted: Bool { feed.fullyExhausted }

    var hasContent: Bool {
        !sections.isEmpty && sections.contains { !$0.articles.isEmpty }
    }

    func load(force: Bool = false) async {
        var next = feed
        await next.runLoad(
            force: force,
            anchorMonth: anchorMonth,
            publish: { feed = $0 }
        ) { month, page, _ in
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
        var next = feed
        await next.runLoadMore(publish: { feed = $0 }) { month, page, _ in
            try await OneClient.articleDiscovery(
                modelID: ContentCategory.ModelID.graphic,
                publishedAt: month,
                sort: ArticleSort.publishedAt.rawValue,
                page: page,
                size: 20
            )
        }
    }
}
