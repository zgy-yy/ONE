import Foundation

/// 业务 API 客户端：选线、签名 POST、具体接口方法。
enum OneClient {
    private static let probeTimeout: TimeInterval = 20

    /// 依次 POST `domain/check`，选第一条可用线路，返回带 `/v2.5` 的基址。
    static func pickBaseURL() async throws -> URL {
        for host in OneTargets.hostBases {
            let url = APIURL.join(base: host, path: "domain/check")
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
        let url = APIURL.join(base: base.absoluteString, path: path)
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

    static func articleDiscovery(
        base: URL,
        token: String,
        request: DiscoveryRequest
    ) async throws -> [ArticleSummary] {
        let envelope = try await post(
            OneApiEnvelope<DiscoveryListPayload>.self,
            base: base,
            path: OneAPI.discoveryPath,
            token: token,
            data: request.formBody()
        )
        guard OneAPI.isSuccess(code: envelope.code) else {
            let detail = envelope.message ?? "code \(envelope.code.map(String.init) ?? "nil")"
            throw OneClientError.apiRejected(detail)
        }
        return envelope.data?.articles ?? []
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
