import Foundation

enum OneClient {
    private static let probeTimeout: TimeInterval = 20

    /// 与 one-web `pickOneBaseUrl`：POST `domain/check`，首个 HTTP 非 5xx 的线路
    static func pickBaseURL() async throws -> URL {
        for host in OneTargets.hostBases {
            let url = TokensAPIPath.join(base: host, path: "domain/check")
            let (statusCode, _) = await HTTPClient.postStatusCode(from: url, timeout: probeTimeout)
            if let statusCode, statusCode < 500 {
                let root = host.hasSuffix("/") ? String(host.dropLast()) : host
                return normalizedBaseURL("\(root)/\(OneTargets.apiVersion)")
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

    private static let apiTimeout: TimeInterval = 30

    /// ONE 业务 POST（base 已含 `v2.5`；`data == nil` 时无 body，如 `getDemandTagList`）
    static func post<T: Decodable>(
        _ type: T.Type,
        base: URL,
        path: String,
        token: String,
        data: [String: String]? = nil
    ) async throws -> T {
        let url = TokensAPIPath.join(base: base.absoluteString, path: path)
        let headers = OneCrypto.makeRequestHeaders(token: token)
        let body = try data.map { try OneCrypto.encryptMapBody($0) }
        return try await HTTPClient.postText(
            type,
            to: url,
            body: body,
            headerFields: headers,
            timeout: apiTimeout,
            responseDecoder: HTTPResponseDecoders.one
        )
    }

    static func getDemandTagList(base: URL, token: String) async throws -> [DemandTag] {
        let envelope = try await post(
            OneApiEnvelope<[DemandTag]>.self,
            base: base,
            path: OneAPI.demandTagListPath,
            token: token,
            data: nil
        )
        guard OneAPI.isSuccess(code: envelope.code) else {
            let detail = envelope.message ?? "code \(envelope.code.map(String.init) ?? "nil")"
            throw OneClientError.apiRejected(detail)
        }
        return envelope.data ?? []
    }
}

enum OneClientError: LocalizedError {
    case noAvailableLine
    case apiRejected(String)
    case missingToken
    case baseNotReady

    var errorDescription: String? {
        switch self {
        case .noAvailableLine: "ONE 线路不可用"
        case .apiRejected(let message): message
        case .missingToken: "缺少 ONE token，请先完成启动拉取"
        case .baseNotReady: "ONE 线路未就绪"
        }
    }
}
