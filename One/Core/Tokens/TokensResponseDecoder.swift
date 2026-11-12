import Foundation

/// `box/api/*` splash 响应：AES-128-CBC + gzip
struct TokensResponseDecoder: HTTPResponseDecoder {
    func decodeResponseBody(_ raw: String) throws -> Data {
        try TokensCrypto.parseResponse(raw)
    }
}
