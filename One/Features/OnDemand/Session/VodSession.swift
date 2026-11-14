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

    private(set) var articlesLoading: Set<Int> = []
    private(set) var articlesLoadingMore: Set<Int> = []

    /// 顶栏锚定/跳转月份；已有分区时由列表滚动，否则重载。
    var listPublishedAt: String = MonthYear.now.apiString

    var listSort: VodArticleSort = .publishedAt {
        didSet {
            guard oldValue != listSort else { return }
            tagsArticles = [:]
        }
    }

    var articleFetchKey: String {
        "\(listPublishedAt)-\(listSort.rawValue)"
    }

    private var tagsArticles: [Int: TagsArticles] = [:]
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

        guard let creds = OneCredentials.pair(tokenPath: OneAPI.demandTagListPath) else {
            lastError = OneCredentials.readinessError
            return
        }

        do {
            tags = try await OneClient.getDemandTagList(base: creds.base, token: creds.token)
            tagsArticles = [:]
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - 文章列表

    func articleSections(for tagID: Int) -> [ArticleMonthSection] {
        tagsArticles[tagID]?.sections ?? []
    }

    func articleError(for tagID: Int) -> String? {
        tagsArticles[tagID]?.error
    }

    func isLoadingArticles(tagID: Int) -> Bool { articlesLoading.contains(tagID) }
    func isLoadingMoreArticles(tagID: Int) -> Bool { articlesLoadingMore.contains(tagID) }

    func showsArticlesEndFooter(tagID: Int) -> Bool {
        guard let state = tagsArticles[tagID], state.loaded else { return false }
        return state.fullyExhausted
    }

    func loadArticles(for tagID: Int, force: Bool = false) async {
        if force { tagsArticles[tagID] = nil }
        guard !articlesLoading.contains(tagID), tagsArticles[tagID]?.loaded != true else { return }

        articlesLoading.insert(tagID)
        defer { articlesLoading.remove(tagID) }

        var state = TagsArticles()
        state.reset()
        tagsArticles[tagID] = state

        await fetchArticlePage(tagID: tagID, month: listPublishedAt, page: 1, newSection: true)
        await advancePastEmptyMonths(tagID: tagID)
        markFullyExhaustedIfNeeded(tagID: tagID)
    }

    func loadMoreArticles(for tagID: Int) async {
        guard let state = tagsArticles[tagID], state.loaded, state.canLoadMore else { return }
        guard !articlesLoading.contains(tagID), !articlesLoadingMore.contains(tagID) else { return }
        guard let next = nextPageRequest(for: state) else {
            markFullyExhaustedIfNeeded(tagID: tagID)
            return
        }

        articlesLoadingMore.insert(tagID)
        defer { articlesLoadingMore.remove(tagID) }

        await fetchArticlePage(tagID: tagID, month: next.month, page: next.page, newSection: next.newSection)
        markFullyExhaustedIfNeeded(tagID: tagID)
    }

    // MARK: - 分页

    private struct PageRequest {
        let month: String
        let page: Int
        let newSection: Bool
    }

    private func nextPageRequest(for state: TagsArticles) -> PageRequest? {
        guard let tail = state.sections.last else { return nil }
        if !tail.monthExhausted {
            return PageRequest(month: tail.month, page: tail.nextPage, newSection: false)
        }
        guard let month = MonthYear(apiString: tail.month)?.previous else { return nil }
        return PageRequest(month: month.apiString, page: 1, newSection: true)
    }

    /// 锚定月无文章时继续拉更早月份，直到有数据或无法继续。
    private func advancePastEmptyMonths(tagID: Int) async {
        while tagsArticles[tagID]?.canLoadMore == true {
            guard let tail = tagsArticles[tagID]?.sections.last, tail.monthExhausted, tail.articles.isEmpty else { break }
            await loadMoreArticles(for: tagID)
        }
    }

    private func markFullyExhaustedIfNeeded(tagID: Int) {
        guard var state = tagsArticles[tagID],
              let tail = state.sections.last,
              tail.monthExhausted,
              MonthYear(apiString: tail.month)?.previous == nil else { return }
        state.fullyExhausted = true
        tagsArticles[tagID] = state
    }

    // MARK: - 网络

    private func fetchArticlePage(tagID: Int, month: String, page: Int, newSection: Bool) async {
        guard let creds = OneCredentials.pair(tokenPath: OneAPI.discoveryPath) else {
            if page == 1, newSection { setError(OneCredentials.readinessError, for: tagID) }
            return
        }

        let request = DiscoveryRequest.vodList(
            demandTagID: tagID,
            publishedAt: month,
            sort: listSort.rawValue,
            page: page,
            size: articlePageSize
        )

        do {
            let list = try await OneClient.articleDiscovery(base: creds.base, token: creds.token, request: request)
            var state = tagsArticles[tagID, default: TagsArticles()]
            state.mergePage(month: month, list: list, page: page, pageSize: articlePageSize, newSection: newSection)
            tagsArticles[tagID] = state
        } catch {
            if page == 1, newSection { setError(error.localizedDescription, for: tagID) }
        }
    }

    private func setError(_ message: String, for tagID: Int) {
        var state = tagsArticles[tagID, default: TagsArticles()]
        state.recordError(message)
        tagsArticles[tagID] = state
    }

}
