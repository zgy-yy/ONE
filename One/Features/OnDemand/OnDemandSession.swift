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

    private var articlesByTagID: [Int: PerTagArticles] = [:]

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
            articlesByTagID = [:]
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - 文章列表

    func articles(for tagID: Int) -> [ArticleSummary] {
        articlesByTagID[tagID]?.items ?? []
    }

    func articleError(for tagID: Int) -> String? {
        articlesByTagID[tagID]?.error
    }

    func isLoadingArticles(tagID: Int) -> Bool {
        articlesLoading.contains(tagID)
    }

    func isLoadingMoreArticles(tagID: Int) -> Bool {
        articlesLoadingMore.contains(tagID)
    }

    func hasMoreArticles(tagID: Int) -> Bool {
        articlesByTagID[tagID]?.hasMore == true
    }

    func showsArticlesEndFooter(tagID: Int) -> Bool {
        guard let state = articlesByTagID[tagID], state.loaded else { return false }
        return !state.hasMore
    }

    func loadArticles(for tagID: Int, force: Bool = false) async {
        if force { articlesByTagID[tagID] = nil }
        guard !articlesLoading.contains(tagID), articlesByTagID[tagID]?.loaded != true else { return }

        articlesLoading.insert(tagID)
        defer { articlesLoading.remove(tagID) }

        await fetchArticlePage(tagID: tagID, page: 1, append: false)
    }

    func loadMoreArticles(for tagID: Int) async {
        guard let state = articlesByTagID[tagID], state.loaded, state.hasMore else { return }
        guard !articlesLoading.contains(tagID), !articlesLoadingMore.contains(tagID) else { return }

        articlesLoadingMore.insert(tagID)
        defer { articlesLoadingMore.remove(tagID) }

        await fetchArticlePage(tagID: tagID, page: state.nextPage, append: true)
    }

    // MARK: - 网络

    private func fetchArticlePage(tagID: Int, page: Int, append: Bool) async {
        guard let (base, token) = oneCredentials(tokenPath: OneAPI.discoveryPath) else {
            if !append {
                var state = articlesByTagID[tagID, default: PerTagArticles()]
                state.recordError(credentialErrorMessage(tokenPath: OneAPI.discoveryPath))
                articlesByTagID[tagID] = state
            }
            return
        }

        let request = DiscoveryRequest.vodList(demandTagID: tagID, page: page, size: articlePageSize)

        do {
            let list = try await OneClient.articleDiscovery(base: base, token: token, request: request)
            var state = articlesByTagID[tagID, default: PerTagArticles()]
            state.mergePage(list, page: page, pageSize: articlePageSize, append: append)
            articlesByTagID[tagID] = state
        } catch where !append {
            var state = articlesByTagID[tagID, default: PerTagArticles()]
            state.recordError(error.localizedDescription)
            articlesByTagID[tagID] = state
        } catch {
            // 加载更多失败时保留已有列表，静默忽略。
        }
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
        if TokensSession.shared.oneToken(forPath: tokenPath) == nil {
            return OneClientError.missingToken.localizedDescription
        }
        return OneClientError.missingToken.localizedDescription
    }
}

private struct PerTagArticles {
    var items: [ArticleSummary] = []
    var error: String?
    var nextPage = 2
    var hasMore = true
    var loaded = false

    mutating func recordError(_ message: String) {
        error = message
        loaded = false
    }

    mutating func mergePage(_ list: [ArticleSummary], page: Int, pageSize: Int, append: Bool) {
        error = nil
        loaded = true
        hasMore = list.count >= pageSize
        nextPage = page + 1

        if append {
            let seen = Set(items.map(\.id))
            items.append(contentsOf: list.filter { !seen.contains($0.id) })
        } else {
            items = list
        }
    }
}
