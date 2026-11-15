import Foundation

/// ONE 请求所需的 base + token（Feature Session 共用）。
///
/// token 由 `TokensSession.oneToken(forPath:)` 按路径挑选：
/// 登录后一般用用户 token；`article/detail` 固定用 `token_one`。
enum OneCredentials {
    @MainActor
    static func pair(tokenPath: String) -> (base: URL, token: String)? {
        guard let base = OneSession.shared.baseURL,
              let token = TokensSession.shared.oneToken(forPath: tokenPath) else { return nil }
        return (base, token)
    }

    @MainActor
    static var readinessError: String {
        OneSession.shared.baseURL == nil
            ? OneClientError.baseNotReady.localizedDescription
            : OneClientError.missingToken.localizedDescription
    }
}
