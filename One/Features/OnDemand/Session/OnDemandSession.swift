import Foundation
import Observation

/// 点播（On-demand）模块状态。
@MainActor
@Observable
final class OnDemandSession {
    static let shared = OnDemandSession()

    private(set) var tags: [DemandTag] = []
    private(set) var isLoading = false
    private(set) var lastError: String?

    private(set) var articlesLoading: Set<Int> = []
    private(set) var articlesLoadingMore: Set<Int> = []

    var listPublishedAt: String = MonthYear.now.apiString {
        didSet {
            guard oldValue != listPublishedAt else { return }
            tagsArticles = [:]
        }
    }

    var listSort: VodArticleSort = .likeNumber {
        didSet {
            guard oldValue != listSort else { return }
            tagsArticles = [:]
        }
    }

    /// 列表请求维度（分类、筛选、排序），供 `task(id:)` 触发重载。
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

    func refresh() async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        guard let (base, token) = oneCredentials(tokenPath: OneAPI.demandTagListPath) else {
            lastError = credentialErrorMessage(tokenPath: OneAPI.demandTagListPath)
            return
        }

        do {
            tags = try await OneClient.getDemandTagList(base: base, token: token)
            tagsArticles = [:]
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - 文章列表

    func articles(for tagID: Int) -> [ArticleSummary] {
        tagsArticles[tagID]?.items ?? []
    }

    func articleError(for tagID: Int) -> String? {
        tagsArticles[tagID]?.error
    }

    func isLoadingArticles(tagID: Int) -> Bool { articlesLoading.contains(tagID) }
    func isLoadingMoreArticles(tagID: Int) -> Bool { articlesLoadingMore.contains(tagID) }
    func hasMoreArticles(tagID: Int) -> Bool { tagsArticles[tagID]?.hasMore == true }

    func showsArticlesEndFooter(tagID: Int) -> Bool {
        guard let state = tagsArticles[tagID], state.loaded else { return false }
        return !state.hasMore
    }

    func loadArticles(for tagID: Int, force: Bool = false) async {
        if force { tagsArticles[tagID] = nil }
        guard !articlesLoading.contains(tagID), tagsArticles[tagID]?.loaded != true else { return }

        articlesLoading.insert(tagID)
        defer { articlesLoading.remove(tagID) }
        await fetchArticlePage(tagID: tagID, page: 1, append: false)
    }

    func loadMoreArticles(for tagID: Int) async {
        guard let state = tagsArticles[tagID], state.loaded, state.hasMore else { return }
        guard !articlesLoading.contains(tagID), !articlesLoadingMore.contains(tagID) else { return }

        articlesLoadingMore.insert(tagID)
        defer { articlesLoadingMore.remove(tagID) }
        await fetchArticlePage(tagID: tagID, page: state.nextPage, append: true)
    }

    // MARK: - 网络

    private func fetchArticlePage(tagID: Int, page: Int, append: Bool) async {
        guard let (base, token) = oneCredentials(tokenPath: OneAPI.discoveryPath) else {
            if !append { setError(credentialErrorMessage(tokenPath: OneAPI.discoveryPath), for: tagID) }
            return
        }

        let request = DiscoveryRequest.vodList(
            demandTagID: tagID,
            publishedAt: listPublishedAt,
            sort: listSort.rawValue,
            page: page,
            size: articlePageSize
        )

        do {
            let list = try await OneClient.articleDiscovery(base: base, token: token, request: request)
            merge(list, tagID: tagID, page: page, append: append)
        } catch where !append {
            setError(error.localizedDescription, for: tagID)
        } catch {
            // 加载更多失败：保留已有列表。
        }
    }

    private func merge(_ list: [ArticleSummary], tagID: Int, page: Int, append: Bool) {
        var state = tagsArticles[tagID, default: TagsArticles()]
        state.mergePage(list, page: page, pageSize: articlePageSize, append: append)
        tagsArticles[tagID] = state
    }

    private func setError(_ message: String, for tagID: Int) {
        var state = tagsArticles[tagID, default: TagsArticles()]
        state.recordError(message)
        tagsArticles[tagID] = state
    }

    private func oneCredentials(tokenPath: String) -> (URL, String)? {
        guard let base = OneSession.shared.baseURL,
              let token = TokensSession.shared.oneToken(forPath: tokenPath) else { return nil }
        return (base, token)
    }

    private func credentialErrorMessage(tokenPath: String) -> String {
        if OneSession.shared.baseURL == nil {
            return OneClientError.baseNotReady.localizedDescription
        }
        return OneClientError.missingToken.localizedDescription
    }
}
