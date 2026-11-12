import Foundation
import Observation

@MainActor
@Observable
final class TokensSession {
    static let shared = TokensSession()

    private(set) var tokenOne: String?
    private(set) var tokenOneVisitor: String?
    private(set) var baseURL: URL?
    private(set) var isLoading = false
    private(set) var lastError: String?
    private(set) var lastUpdated: Date?

    private init() {}

    /// 进入 App 时调用；已有缓存且未强制刷新时可跳过
    func prepare() async {
        guard tokenOne == nil, tokenOneVisitor == nil else { return }
        await refresh()
    }

    func refresh() async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            let result = try await TokensClient.fetch()
            apply(result)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func apply(_ result: TokensResult) {
        baseURL = result.baseURL
        tokenOne = result.tokens.token(named: "token_one")
        tokenOneVisitor = result.tokens.token(named: "token_one_visitor")
        lastUpdated = Date()
    }

    /// 与 one-web `pickOneToken` 一致
    func oneToken(forPath path: String) -> String? {
        if path.contains("article/detail"),
           let tokenOne, !tokenOne.isEmpty
        {
            return tokenOne
        }
        if let tokenOneVisitor, !tokenOneVisitor.isEmpty {
            return tokenOneVisitor
        }
        return tokenOne
    }

    var statusSummary: String {
        if isLoading { return "正在拉取 Tokens…" }
        if let lastError { return lastError }
        if tokenOne != nil || tokenOneVisitor != nil {
            let one = tokenOne != nil ? "有" : "无"
            let visitor = tokenOneVisitor != nil ? "有" : "无"
            return "token_one: \(one)，token_one_visitor: \(visitor)"
        }
        return "尚未拉取 Tokens"
    }
}

private extension [TokenEntry] {
    func token(named name: String) -> String? {
        first { $0.name == name }?.token
    }
}
