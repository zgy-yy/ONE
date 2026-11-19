import Foundation

/// ONE 业务 API 入口。
///
/// 用法（Feature 层）：
/// ```swift
/// let detail = try await OneClient.articleDetail(articleID: id)
/// ```
///
/// 内部流程：取 base + token → 签名 Header → 加密 body → `HTTPClient` 发请求。
/// 业务接口按域拆文件：`ArticleAPI` / `SeriesAPI` / `CommentAPI` / `ActorAPI` / `UserAPI`。
enum OneClient {
    static let probeTimeout: TimeInterval = 20
    static let apiTimeout: TimeInterval = 30

    /// 探测 `domain/check`，返回第一个可用的 `…/v2.5` 基址。
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

    /// 统一 POST：自动带 token / 签名 / 加密。
    static func post<T: Decodable>(
        _ type: T.Type,
        path: String,
        data: [String: String]? = nil
    ) async throws -> T {
        let creds = try await MainActor.run {
            try OneCredentials.requirePair(tokenPath: path)
        }
        let url = APIURL.join(base: creds.base.absoluteString, path: path)
        let userKey = (path == OneAPI.sendSMSPath || path == OneAPI.userLoginPath)
            ? ""
            : OneAuthStore.userKeyHeader
        let headers = OneCrypto.makeRequestHeaders(token: creds.token, userKey: userKey)
        let body = try data.map { try OneCrypto.encryptMapBody($0) }
        return try await HTTPClient.post(
            type,
            to: url,
            body: body,
            headerFields: headers,
            timeout: apiTimeout,
            responseDecoder: HTTPResponseDecoders.one
        )
    }

    /// 校验 `code` 是否成功，成功则返回 `data`。
    static func unwrap<T>(_ envelope: OneApiEnvelope<T>) throws -> T? {
        guard OneAPI.isSuccess(code: envelope.code) else {
            let detail = envelope.message ?? "code \(envelope.code.map(String.init) ?? "nil")"
            throw OneClientError.apiRejected(detail)
        }
        return envelope.data
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
