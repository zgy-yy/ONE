import Foundation

/// ONE 业务 API（`OneTargets.bases`）响应解密
struct OneResponseDecoder: HTTPResponseDecoder {
    func decodeResponseBody(_ raw: String) throws -> Data {
        try OneCrypto.parseOneResponse(raw)
    }
}
