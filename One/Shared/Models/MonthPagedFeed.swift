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

    /// 有旧数据时先保留列表，等首包返回再整表替换（避免卸掉 List 取消 refreshable）。
    private var replaceAfterFetch = false

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
        replaceAfterFetch = false
    }

    mutating func beginLoad(force: Bool = false) -> Bool {
        if force {
            // 已有内容：保留 sections，AsyncPage 继续显示 List，下拉刷新任务不被取消。
            if !state.sections.isEmpty {
                guard !isLoading, !isLoadingMore else { return false }
                isLoading = true
                state.error = nil
                replaceAfterFetch = true
                return true
            }
            clear()
        }
        guard !isLoading, !loaded else { return false }
        isLoading = true
        state.reset()
        replaceAfterFetch = false
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

    /// Session 用：`begin` 后立刻 `publish`（让 UI 看到 loading），`perform` 后再 `publish`。
    mutating func runLoad(
        force: Bool,
        anchorMonth: String,
        publish: (MonthPagedFeed) -> Void,
        fetch: PageFetch
    ) async {
        guard beginLoad(force: force) else {
            publish(self)
            return
        }
        publish(self)
        await performLoad(anchorMonth: anchorMonth, fetch: fetch)
        publish(self)
    }

    mutating func runLoadMore(
        publish: (MonthPagedFeed) -> Void,
        fetch: PageFetch
    ) async {
        guard beginLoadMore() else {
            publish(self)
            return
        }
        publish(self)
        await performLoadMore(fetch: fetch)
        publish(self)
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
            if Task.isCancelled { return }
            if replaceAfterFetch {
                state.reset()
                replaceAfterFetch = false
            }
            state.mergePage(
                month: request.month,
                list: list,
                page: request.page,
                pageSize: pageSize,
                newSection: request.newSection
            )
        } catch {
            if error.isRequestCancellation {
                replaceAfterFetch = false
                return
            }
            if request.page == 1, request.newSection, state.sections.isEmpty {
                state.recordError(error.localizedDescription)
            }
        }
    }
}
