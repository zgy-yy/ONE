import Foundation

/// 将 HTTP 原始响应体转为可 `JSONDecoder` 的 JSON 数据（可插拔）
protocol HTTPResponseDecoder: Sendable {
    func decodeResponseBody(_ raw: String) throws -> Data
}

enum HTTPResponseDecoderError: LocalizedError {
    case emptyBody
    case invalidUTF8

    var errorDescription: String? {
        switch self {
        case .emptyBody: "响应体为空"
        case .invalidUTF8: "响应体不是有效 UTF-8"
        }
    }
}

/// 已是明文 JSON，不做解密
struct PlainJSONResponseDecoder: HTTPResponseDecoder {
    func decodeResponseBody(_ raw: String) throws -> Data {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { throw HTTPResponseDecoderError.emptyBody }
        guard let data = trimmed.data(using: .utf8) else {
            throw HTTPResponseDecoderError.invalidUTF8
        }
        return data
    }
}

enum HTTPResponseDecoders {
    static let plain = PlainJSONResponseDecoder()
    static let tokens = TokensResponseDecoder()
    static let one = OneResponseDecoder()
}
