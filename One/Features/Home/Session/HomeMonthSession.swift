import Foundation
import Observation

/// 点击首页日期后：`article/discovery`（图文），按月分段并向下加载更早月份。
@MainActor
@Observable
final class HomeMonthSession {
    let anchorMonth: String

    private(set) var sections: [ArticleMonthSection] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var error: String?
    private(set) var loaded = false
    private(set) var fullyExhausted = false

    private let pageSize = 20
    private var state = TagsArticles()

    init(monthAPIString: String) {
        self.anchorMonth = monthAPIString
    }

    var hasContent: Bool {
        !sections.isEmpty && sections.contains { !$0.articles.isEmpty }
    }

    func load(force: Bool = false) async {
        if force {
            state.reset()
            sections = []
            error = nil
            loaded = false
            fullyExhausted = false
        }
        guard !isLoading, !loaded else { return }

        isLoading = true
        error = nil
        defer { isLoading = false }

        state.reset()
        await fetchPage(month: anchorMonth, page: 1, newSection: true)
        await advancePastEmptyMonths()
        state.markFullyExhaustedIfNeeded()
        syncFromState()
    }

    func loadMore() async {
        guard loaded, !fullyExhausted, state.canLoadMore else { return }
        guard !isLoading, !isLoadingMore else { return }
        guard let next = state.nextPageRequest else {
            state.markFullyExhaustedIfNeeded()
            syncFromState()
            return
        }

        isLoadingMore = true
        defer { isLoadingMore = false }

        await fetchPage(month: next.month, page: next.page, newSection: next.newSection)
        await advancePastEmptyMonths()
        state.markFullyExhaustedIfNeeded()
        syncFromState()
    }

    // MARK: - Private

    private func advancePastEmptyMonths() async {
        var hops = 0
        while state.shouldAdvancePastEmptyTail, hops < 36 {
            hops += 1
            guard let next = state.nextPageRequest else { break }
            await fetchPage(month: next.month, page: next.page, newSection: next.newSection)
        }
    }

    private func fetchPage(month: String, page: Int, newSection: Bool) async {
        do {
            let list = try await OneClient.articleDiscovery(
                modelID: ContentCategory.ModelID.graphic,
                publishedAt: month,
                sort: VodArticleSort.publishedAt.rawValue,
                page: page,
                size: pageSize
            )
            state.mergePage(
                month: month,
                list: list,
                page: page,
                pageSize: pageSize,
                newSection: newSection
            )
            loaded = true
            error = nil
        } catch {
            if page == 1, newSection {
                self.error = error.localizedDescription
                loaded = false
            }
        }
    }

    private func syncFromState() {
        sections = state.sections
        fullyExhausted = state.fullyExhausted
        if let message = state.error {
            error = message
        }
    }
}
