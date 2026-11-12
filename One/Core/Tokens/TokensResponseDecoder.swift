import Foundation

/// 适配 `HTTPResponseDecoder` 协议，内部调用 `TokensCrypto.parseResponse`。
struct TokensResponseDecoder: HTTPResponseDecoder {
    func decodeResponseBody(_ raw: String) throws -> Data {
        try TokensCrypto.parseResponse(raw)
    }
}
