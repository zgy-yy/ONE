import Foundation

/// ONE `v2.5/*` 响应解密
struct OneResponseDecoder: HTTPResponseDecoder {
    func decodeResponseBody(_ raw: String) throws -> Data {
        try OneCrypto.parseOneResponse(raw)
    }
}
