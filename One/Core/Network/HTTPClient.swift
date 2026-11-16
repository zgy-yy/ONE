import Alamofire
import Foundation

/// 项目统一的 HTTP 封装（基于 [Alamofire](https://github.com/Alamofire/Alamofire)）。
///
/// 学习要点：
/// - `request`：拿响应原文（String），GET/POST 共用。
/// - `get` / `post`：在原文基础上解密并 JSON 解码成结构体。
/// - `responseDecoder`：壳 / ONE 接口常先解密再 JSON。
enum HTTPClient {
    private static let session: Session = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        return Session(configuration: configuration)
    }()

    // MARK: - Raw

    /// 发请求并返回响应原文（不 JSON 解码）。
    /// - Parameters:
    ///   - method: `.get` / `.post` 等
    ///   - body: 原始字符串 body（如加密表单）；GET 一般不传
    static func request(
        _ method: HTTPMethod,
        url: URL,
        body: String? = nil,
        headerFields: [String: String] = [:],
        headers: HTTPHeaders = [],
        timeout: TimeInterval? = nil
    ) async throws -> String {
        let merged = mergeHeaders(headerFields: headerFields, headers: headers)
        return try await session.request(
            url,
            method: method,
            headers: merged,
            requestModifier: { req in
                if let timeout { req.timeoutInterval = timeout }
                if let body { req.httpBody = Data(body.utf8) }
            }
        )
        .serializingString()
        .value
    }

    // MARK: - JSON

    static func get<T: Decodable>(
        _ type: T.Type,
        from url: URL,
        headerFields: [String: String] = [:],
        headers: HTTPHeaders = [],
        timeout: TimeInterval? = nil,
        responseDecoder: (any HTTPResponseDecoder)? = nil
    ) async throws -> T {
        let merged = mergeHeaders(headerFields: headerFields, headers: headers)
        if let responseDecoder {
            let raw = try await request(.get, url: url, headers: merged, timeout: timeout)
            return try decode(type, raw: raw, responseDecoder: responseDecoder)
        }
        return try await session.request(url, method: .get, headers: merged, requestModifier: { request in
            if let timeout { request.timeoutInterval = timeout }
        })
        .validate(statusCode: 200 ..< 300)
        .serializingDecodable(T.self)
        .value
    }

    /// POST（字符串 body，如 ONE 加密表单）→ 解密 → 解成模型。
    static func post<Response: Decodable>(
        _ type: Response.Type,
        to url: URL,
        body: String? = nil,
        headerFields: [String: String] = [:],
        headers: HTTPHeaders = [],
        timeout: TimeInterval? = nil,
        responseDecoder: any HTTPResponseDecoder
    ) async throws -> Response {
        let raw = try await request(
            .post,
            url: url,
            body: body,
            headerFields: headerFields,
            headers: headers,
            timeout: timeout
        )
        return try decode(type, raw: raw, responseDecoder: responseDecoder)
    }

    // MARK: - Probe

    /// 仅探测 HTTP 状态码（如 `box/api/ping`）
    static func getStatusCode(
        from url: URL,
        timeout: TimeInterval? = nil
    ) async -> (statusCode: Int?, error: Error?) {
        let response = await session.request(url, method: .get, requestModifier: { request in
            if let timeout {
                request.timeoutInterval = timeout
            }
        })
        .serializingData()
        .response
        return (response.response?.statusCode, response.error)
    }

    /// POST 探测状态码（如 ONE `domain/check`）
    static func postStatusCode(
        from url: URL,
        timeout: TimeInterval? = nil
    ) async -> (statusCode: Int?, error: Error?) {
        let response = await session.request(url, method: .post, requestModifier: { request in
            if let timeout {
                request.timeoutInterval = timeout
            }
        })
        .serializingData()
        .response
        return (response.response?.statusCode, response.error)
    }

    // MARK: - Private

    private static func decode<T: Decodable>(
        _ type: T.Type,
        raw: String,
        responseDecoder: any HTTPResponseDecoder
    ) throws -> T {
        let data = try responseDecoder.decodeResponseBody(raw)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private static func mergeHeaders(headerFields: [String: String], headers: HTTPHeaders) -> HTTPHeaders {
        if headers.isEmpty { return HTTPHeaders(headerFields) }
        return headers
    }
}
