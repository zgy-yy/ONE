import Foundation

/// 封面图专用 AES 密钥（与业务 API 的 `OneCrypto` 不是同一套）。
enum OneImageCrypto {
    private static let key = Data("saIZXc4yMvq0Iz56".utf8)
    private static let iv = Data("kbJYtBJUECT0oyjo".utf8)

    static func decrypt(cipher: Data) throws -> Data {
        try AESCBC.decrypt(cipher: cipher, key: key, iv: iv)
    }

    static func isPlainImage(_ data: Data) -> Bool {
        guard data.count >= 3 else { return false }
        let bytes = [UInt8](data.prefix(12))
        if bytes.count >= 3, bytes[0] == 0xff, bytes[1] == 0xd8 { return true }
        if bytes.count >= 4, bytes[0] == 0x89, bytes[1] == 0x50, bytes[2] == 0x4e { return true }
        if bytes.count >= 3, bytes[0] == 0x47, bytes[1] == 0x49, bytes[2] == 0x46 { return true }
        if bytes.count >= 12, bytes[0] == 0x52, bytes[1] == 0x49, bytes[8] == 0x57, bytes[9] == 0x45 { return true }
        return false
    }
}
