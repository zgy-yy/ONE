import Foundation

enum OneClient {
    private static let probeTimeout: TimeInterval = 20

    /// 与 one-web `pickOneBaseUrl`：POST `domain/check`，首个 HTTP 非 5xx 的线路
    static func pickBaseURL() async throws -> URL {
        for base in OneTargets.bases {
            let url = TokensAPIPath.join(base: base, path: "domain/check")
            let (statusCode, _) = await HTTPClient.postStatusCode(from: url, timeout: probeTimeout)
            if let statusCode, statusCode < 500 {
                return normalizedBaseURL(base)
            }
        }
        throw OneClientError.noAvailableLine
    }

    private static func normalizedBaseURL(_ base: String) -> URL {
        let normalized = base.hasSuffix("/") ? base : base + "/"
        guard let url = URL(string: normalized) else {
            preconditionFailure("Invalid one base: \(base)")
        }
        return url
    }
}

enum OneClientError: LocalizedError {
    case noAvailableLine

    var errorDescription: String? { "ONE 线路不可用" }
}
