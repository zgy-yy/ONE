import Foundation

/// 按月分页：锚定月 → 空月往更早 hop → 触底 loadMore。
///
/// struct：`begin*` 后立刻写回 Session，再 `perform*`，UI 才能看到 loading。
struct MonthPagedFeed {
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
    /// 已有内容且无法再请求下一页时显示「到底」文案（不依赖是否已写 fullyExhausted 标记）。
    var showsEndFooter: Bool {
        guard loaded, !isLoading, !isLoadingMore else { return false }
        guard sections.contains(where: { !$0.articles.isEmpty }) else { return false }
        return !canLoadMore
    }

    mutating func clear() {
        state.reset()
        isLoading = false
        isLoadingMore = false
    }

    mutating func beginLoad(force: Bool = false) -> Bool {
        if force { clear() }
        guard !isLoading, !loaded else { return false }
        isLoading = true
        state.reset()
        return true
    }

    mutating func beginLoadMore() -> Bool {
        guard !isLoading, !isLoadingMore else { return false }
        guard canLoadMore else {
            state.markFullyExhaustedIfNeeded()
            return false
        }
        isLoadingMore = true
        return true
    }

    mutating func performLoad(anchorMonth: String, fetch: PageFetch) async {
        defer { isLoading = false }
        await run(.init(month: anchorMonth, page: 1, newSection: true), fetch: fetch)
    }

    mutating func performLoadMore(fetch: PageFetch) async {
        defer { isLoadingMore = false }
        guard let next = state.nextPageRequest else {
            state.markFullyExhaustedIfNeeded()
            return
        }
        await run(next, fetch: fetch)
    }

    private mutating func run(_ first: MonthPageRequest, fetch: PageFetch) async {
        await fetchPage(first, fetch: fetch)
        var hops = 0
        while state.shouldAdvancePastEmptyTail, hops < maxEmptyMonthHops {
            hops += 1
            guard let next = state.nextPageRequest else { break }
            await fetchPage(next, fetch: fetch)
        }
        state.markFullyExhaustedIfNeeded()
    }

    private mutating func fetchPage(_ request: MonthPageRequest, fetch: PageFetch) async {
        do {
            let list = try await fetch(request.month, request.page, request.newSection)
            state.mergePage(
                month: request.month,
                list: list,
                page: request.page,
                pageSize: pageSize,
                newSection: request.newSection
            )
        } catch {
            if request.page == 1, request.newSection {
                state.recordError(error.localizedDescription)
            }
        }
    }
}
