import Foundation

/// 按月串联分页编排：锚定月 → 空月自动往更早月份 hop → 触底 loadMore。
///
/// 状态机在 `MonthArticlesState`；本类型负责 load / loadMore / 跳空月。
/// 网络请求由调用方通过 `fetch` 闭包注入。
struct MonthPagedFeed {
    /// `(month, page, newSection) -> 本页文章`
    typealias PageFetch = (_ month: String, _ page: Int, _ newSection: Bool) async throws -> [ArticleSummary]

    private(set) var state = MonthArticlesState()
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    var pageSize: Int

    private let maxEmptyMonthHops = 36

    init(pageSize: Int = 20) {
        self.pageSize = pageSize
    }

    var sections: [ArticleMonthSection] { state.sections }
    var error: String? { state.error }
    var loaded: Bool { state.loaded }
    var fullyExhausted: Bool { state.fullyExhausted }
    var canLoadMore: Bool { state.canLoadMore }
    var showsEndFooter: Bool { state.loaded && state.fullyExhausted }

    mutating func clear() {
        state.reset()
        isLoading = false
        isLoadingMore = false
    }

    /// 从锚定月份拉第一页；若该月为空则继续往更早月份。
    mutating func load(
        anchorMonth: String,
        force: Bool = false,
        fetch: PageFetch
    ) async {
        if force { clear() }
        guard !isLoading, !state.loaded else { return }

        isLoading = true
        defer { isLoading = false }

        state.reset()
        await fetchPage(month: anchorMonth, page: 1, newSection: true, fetch: fetch)
        await advancePastEmptyMonths(fetch: fetch)
        state.markFullyExhaustedIfNeeded()
    }

    /// 触底加载：同月下一页或更早月份；空月会自动 hop。
    mutating func loadMore(fetch: PageFetch) async {
        guard state.loaded, !state.fullyExhausted, state.canLoadMore else { return }
        guard !isLoading, !isLoadingMore else { return }
        guard let next = state.nextPageRequest else {
            state.markFullyExhaustedIfNeeded()
            return
        }

        isLoadingMore = true
        defer { isLoadingMore = false }

        await fetchPage(
            month: next.month,
            page: next.page,
            newSection: next.newSection,
            fetch: fetch
        )
        await advancePastEmptyMonths(fetch: fetch)
        state.markFullyExhaustedIfNeeded()
    }

    // MARK: - Private

    private mutating func advancePastEmptyMonths(fetch: PageFetch) async {
        var hops = 0
        while state.shouldAdvancePastEmptyTail, hops < maxEmptyMonthHops {
            hops += 1
            guard let next = state.nextPageRequest else { break }
            await fetchPage(
                month: next.month,
                page: next.page,
                newSection: next.newSection,
                fetch: fetch
            )
        }
    }

    private mutating func fetchPage(
        month: String,
        page: Int,
        newSection: Bool,
        fetch: PageFetch
    ) async {
        do {
            let list = try await fetch(month, page, newSection)
            state.mergePage(
                month: month,
                list: list,
                page: page,
                pageSize: pageSize,
                newSection: newSection
            )
        } catch {
            if page == 1, newSection {
                state.recordError(error.localizedDescription)
            }
        }
    }
}
