import Foundation

/// ONE 请求所需的 base + token（Feature Session 共用）。
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
