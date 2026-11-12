import Foundation
import Observation

/// 点播 Tab 的状态中心（类似 MVVM 里的 ViewModel）。
///
/// - `@Observable`：Swift 观察宏，属性变化时绑定它的 SwiftUI View 会刷新。
/// - `@MainActor`：保证修改 UI 相关状态在主线程。
/// - `static let shared`：单例；全 App 共用一份分类与列表缓存。
@MainActor
@Observable
final class TabSession {
    static let shared = TabSession()

    /// 顶栏分类（`getDemandTagList`）。
    private(set) var tags: [DemandTag] = []
    private(set) var isLoading = false
    private(set) var lastError: String?

    /// 按分类 ID 缓存文章列表。
    private(set) var articlesByTagID: [Int: [ArticleSummary]] = [:]
    private(set) var articleErrorsByTagID: [Int: String] = [:]
    /// 正在加载列表的分类 ID 集合。
    private(set) var articlesLoading: Set<Int> = []

    private init() {}

    /// 首次进入点播时拉分类。
    func loadIfNeeded() async {
        guard tags.isEmpty, !isLoading else { return }
        await refresh()
    }

    /// 重新拉顶栏分类；会清空已缓存的文章列表。
    func refresh() async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        guard let base = OneSession.shared.baseURL else {
            lastError = OneClientError.baseNotReady.localizedDescription
            return
        }
        guard let token = TokensSession.shared.oneToken(forPath: OneAPI.demandTagListPath) else {
            lastError = OneClientError.missingToken.localizedDescription
            return
        }

        do {
            tags = try await OneClient.getDemandTagList(base: base, token: token)
            articlesByTagID = [:]
            articleErrorsByTagID = [:]
        } catch {
            lastError = error.localizedDescription
        }
    }

    func articles(for tagID: Int) -> [ArticleSummary] {
        articlesByTagID[tagID] ?? []
    }

    func articleError(for tagID: Int) -> String? {
        articleErrorsByTagID[tagID]
    }

    func isLoadingArticles(tagID: Int) -> Bool {
        articlesLoading.contains(tagID)
    }

    /// 按分类拉 discovery 列表；`force` 为 true 时忽略缓存重新请求。
    func loadArticles(for tagID: Int, force: Bool = false) async {
        if !force, articlesByTagID[tagID] != nil || articlesLoading.contains(tagID) {
            return
        }

        articlesLoading.insert(tagID)
        articleErrorsByTagID[tagID] = nil
        defer { articlesLoading.remove(tagID) }

        guard let base = OneSession.shared.baseURL else {
            articleErrorsByTagID[tagID] = OneClientError.baseNotReady.localizedDescription
            return
        }
        guard let token = TokensSession.shared.oneToken(forPath: OneAPI.discoveryPath) else {
            articleErrorsByTagID[tagID] = OneClientError.missingToken.localizedDescription
            return
        }

        let request = DiscoveryRequest.vodList(demandTagID: tagID)

        do {
            let list = try await OneClient.articleDiscovery(base: base, token: token, request: request)
            articlesByTagID[tagID] = list
        } catch {
            articleErrorsByTagID[tagID] = error.localizedDescription
        }
    }
}
