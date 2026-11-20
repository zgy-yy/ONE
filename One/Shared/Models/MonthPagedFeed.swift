import Foundation
import Observation

/// 按月分页：锚定月 → 空月往更早 hop → 触底 loadMore。
///
/// `@Observable` class：改 `isLoading` / `sections` 可直接驱动绑定该实例的视图。
@MainActor
@Observable
final class MonthPagedFeed {
    typealias PageFetch = (_ month: String, _ page: Int, _ newSection: Bool) async throws -> [ArticleSummary]

    /// 分区数据与分页游标（`isLoading` 等 UI 节奏在 Feed 这一层）。
    private var monthArticles = MonthArticlesState()
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    let pageSize: Int

    private let maxEmptyMonthHops = 36

    init(pageSize: Int = 20) {
        self.pageSize = pageSize
    }

    var sections: [ArticleMonthSection] { monthArticles.sections }
    var error: String? { monthArticles.error }
    var loaded: Bool { monthArticles.loaded }
    var fullyExhausted: Bool { monthArticles.fullyExhausted }
    var canLoadMore: Bool { monthArticles.canLoadMore }

    var showsEndFooter: Bool {
        guard loaded, !isLoading, !isLoadingMore else { return false }
        guard sections.contains(where: { !$0.articles.isEmpty }) else { return false }
        return !canLoadMore
    }

    func runLoad(force: Bool = false, anchorMonth: String, fetch: PageFetch) async {
        if force {
            guard !isLoading, !isLoadingMore else { return }
            isLoading = true
            monthArticles.error = nil
            monthArticles.sections = []
            monthArticles.fullyExhausted = false
        } else {
            guard !isLoading, !loaded else { return }
            isLoading = true
            monthArticles.reset()
        }
        defer { isLoading = false }
        await run(.init(month: anchorMonth, page: 1, newSection: true), fetch: fetch)
    }

    func runLoadMore(fetch: PageFetch) async {
        guard !isLoading, !isLoadingMore else { return }
        guard canLoadMore else {
            monthArticles.markFullyExhaustedIfNeeded()
            return
        }
        isLoadingMore = true
        defer { isLoadingMore = false }
        guard let next = monthArticles.nextPageRequest else {
            monthArticles.markFullyExhaustedIfNeeded()
            return
        }
        await run(next, fetch: fetch)
    }

    private func run(_ first: MonthPageRequest, fetch: PageFetch) async {
        await fetchPage(first, fetch: fetch)
        var hops = 0
        while monthArticles.shouldAdvancePastEmptyTail, hops < maxEmptyMonthHops {
            hops += 1
            guard let next = monthArticles.nextPageRequest else { break }
            await fetchPage(next, fetch: fetch)
        }
        monthArticles.markFullyExhaustedIfNeeded()
    }

    private func fetchPage(_ request: MonthPageRequest, fetch: PageFetch) async {
        do {
            let list = try await fetch(request.month, request.page, request.newSection)
            if Task.isCancelled { return }
            monthArticles.mergePage(
                month: request.month,
                list: list,
                page: request.page,
                pageSize: pageSize,
                newSection: request.newSection
            )
        } catch {
            if error.isRequestCancellation { return }
            if request.page == 1, request.newSection, monthArticles.sections.isEmpty {
                monthArticles.recordError(error.localizedDescription)
            }
        }
    }
}