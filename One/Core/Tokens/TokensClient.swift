import Foundation

/// 壳（Box）网络：先 ping 选线路，再拉 `splash` 配置。
enum TokensClient {
    private static let pingTimeout: TimeInterval = 12

    struct LineProbe: Sendable {
        let base: String
        let pingURL: String
        let statusCode: Int?
        let errorMessage: String?

        var line: String {
            if let errorMessage {
                return "\(pingURL) → 失败: \(errorMessage)"
            }
            return "\(pingURL) → HTTP \(statusCode ?? -1)"
        }
    }

    /// 探测可用壳线路（`box/api/ping`）
    static func pickBaseURL() async throws -> URL {
        var probes: [LineProbe] = []
        for base in TokensTargets.bases {
            let url = TokensAPIPath.join(base: base, path: "box/api/ping")
            let (statusCode, error) = await HTTPClient.getStatusCode(from: url, timeout: pingTimeout)
            probes.append(
                LineProbe(
                    base: base,
                    pingURL: url.absoluteString,
                    statusCode: statusCode,
                    errorMessage: error?.localizedDescription
                )
            )
            if statusCode == 200 {
                return normalizedBaseURL(base)
            }
        }
        throw TokensClientError.noAvailableLine(probes: probes)
    }

    /// `GET box/api/splash` → token 列表等配置
    static func fetch() async throws -> TokensResult {
        let root = try await pickBaseURL()
        let path = "box/api/splash"
        let url = TokensAPIPath.join(base: root.absoluteString, path: path)
        let envelope = try await HTTPClient.get(
            SplashEnvelope.self,
            from: url,
            headerFields: TokensCrypto.makeRequestHeaders(path: path),
            responseDecoder: HTTPResponseDecoders.tokens
        )
        return TokensResult(baseURL: root, envelope: envelope)
    }

    private static func normalizedBaseURL(_ base: String) -> URL {
        let normalized = base.hasSuffix("/") ? base : base + "/"
        guard let url = URL(string: normalized) else {
            preconditionFailure("Invalid tokens base: \(base)")
        }
        return url
    }
}

enum TokensClientError: LocalizedError {
    case noAvailableLine(probes: [TokensClient.LineProbe])

    var errorDescription: String? {
        switch self {
        case .noAvailableLine(let probes):
            let lines = probes.map(\.line)
            if lines.isEmpty {
                return "Tokens 线路不可用"
            }
            return "Tokens 线路不可用\n" + lines.joined(separator: "\n")
        }
    }
}
