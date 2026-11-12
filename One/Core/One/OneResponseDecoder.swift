import Foundation

/// 把业务 API 原始响应转成 JSON `Data`（明文或 AES）。
struct OneResponseDecoder: HTTPResponseDecoder {
    func decodeResponseBody(_ raw: String) throws -> Data {
        try OneCrypto.parseOneResponse(raw)
    }
}
