import Alamofire
import Foundation

enum HTTPClient {
    private static let session: Session = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        return Session(configuration: configuration)
    }()

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
            let raw = try await getText(from: url, headers: merged, timeout: timeout)
            let data = try responseDecoder.decodeResponseBody(raw)
            return try JSONDecoder().decode(T.self, from: data)
        }
        return try await session.request(url, method: .get, headers: merged, requestModifier: { request in
            if let timeout { request.timeoutInterval = timeout }
        })
        .validate(statusCode: 200 ..< 300)
        .serializingDecodable(T.self)
        .value
    }

    static func post<Body: Encodable, Response: Decodable>(
        _ type: Response.Type,
        to url: URL,
        body: Body,
        headerFields: [String: String] = [:],
        headers: HTTPHeaders = [],
        timeout: TimeInterval? = nil,
        responseDecoder: (any HTTPResponseDecoder)? = nil
    ) async throws -> Response {
        var merged = mergeHeaders(headerFields: headerFields, headers: headers)
        if merged["Content-Type"] == nil {
            merged.add(.contentType("application/json"))
        }
        let request = session.request(
            url,
            method: .post,
            parameters: body,
            encoder: JSONParameterEncoder.default,
            headers: merged,
            requestModifier: { req in
                if let timeout { req.timeoutInterval = timeout }
            }
        )
        if let responseDecoder {
            let raw = try await request.serializingString().value
            let data = try responseDecoder.decodeResponseBody(raw)
            return try JSONDecoder().decode(Response.self, from: data)
        }
        return try await request
            .validate(statusCode: 200 ..< 300)
            .serializingDecodable(Response.self)
            .value
    }

    /// POST 原始字符串 body（如 ONE 加密表单），响应可走 `responseDecoder`
    static func postText<Response: Decodable>(
        _ type: Response.Type,
        to url: URL,
        body: String?,
        headerFields: [String: String] = [:],
        headers: HTTPHeaders = [],
        timeout: TimeInterval? = nil,
        responseDecoder: (any HTTPResponseDecoder)? = nil
    ) async throws -> Response {
        var merged = mergeHeaders(headerFields: headerFields, headers: headers)
        let request = session.request(
            url,
            method: .post,
            headers: merged,
            requestModifier: { req in
                if let timeout { req.timeoutInterval = timeout }
                if let body { req.httpBody = Data(body.utf8) }
            }
        )
        if let responseDecoder {
            let raw = try await request.serializingString().value
            let data = try responseDecoder.decodeResponseBody(raw)
            return try JSONDecoder().decode(Response.self, from: data)
        }
        return try await request
            .validate(statusCode: 200 ..< 300)
            .serializingDecodable(Response.self)
            .value
    }

    // MARK: - Raw

    static func getText(
        from url: URL,
        headerFields: [String: String] = [:],
        timeout: TimeInterval? = nil
    ) async throws -> String {
        try await getText(from: url, headers: HTTPHeaders(headerFields), timeout: timeout)
    }

    static func getText(
        from url: URL,
        headers: HTTPHeaders = [],
        timeout: TimeInterval? = nil
    ) async throws -> String {
        try await session.request(url, method: .get, headers: headers, requestModifier: { request in
            if let timeout {
                request.timeoutInterval = timeout
            }
        })
        .serializingString()
        .value
    }

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

    private static func mergeHeaders(headerFields: [String: String], headers: HTTPHeaders) -> HTTPHeaders {
        if headers.isEmpty { return HTTPHeaders(headerFields) }
        return headers
    }
}
