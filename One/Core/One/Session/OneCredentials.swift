import Foundation

/// ONE 请求所需的 base + token（由 `OneClient` 内部取用）。
///
/// token 由 `TokensSession.oneToken(forPath:)` 按路径挑选：
/// 登录后一般用用户 token；仅拉播放地址用 `token_one`。
enum OneCredentials {
    @MainActor
    static func requirePair(tokenPath: String) throws -> (base: URL, token: String) {
        guard let base = OneSession.shared.baseURL else {
            throw OneClientError.baseNotReady
        }
        guard let token = TokensSession.shared.oneToken(forPath: tokenPath) else {
            throw OneClientError.missingToken
        }
        return (base, token)
    }
}
