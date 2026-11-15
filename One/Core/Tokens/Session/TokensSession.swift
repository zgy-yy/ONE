import Foundation
import Observation

/// 壳配置会话：内存里保存 JWT、壳基址、封面/点播 CDN 基址。
///
/// 启动时由 `EntryView` 调用 `prepare()`；各业务 Session 通过 `shared` 读取 token。
@MainActor
@Observable
final class TokensSession {
    static let shared = TokensSession()

    private(set) var tokenOne: String?
    private(set) var tokenOneVisitor: String?
    private(set) var baseURL: URL?
    private(set) var oneImgCDN: String?
    private(set) var oneVideoCDN: String?
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
        let cdns = TokensCDN.extract(from: result.envelope.data)
        oneImgCDN = cdns.oneImg.isEmpty ? nil : cdns.oneImg
        oneVideoCDN = cdns.oneVideo.isEmpty ? nil : cdns.oneVideo
        lastUpdated = Date()
    }

    /// 按接口路径挑选 JWT。
    /// - 发短信 / 登录：用游客 token
    /// - 已登录：优先用户 token
    /// - `article/detail`：优先壳里的登录 token，再游客
    func oneToken(forPath path: String) -> String? {
        if path == OneAPI.sendSMSPath || path == OneAPI.userLoginPath {
            return tokenOneVisitor ?? tokenOne
        }
        if let login = OneAuthStore.loginToken {
            return login
        }
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
