import CommonCrypto
import Foundation

enum OneCryptoError: LocalizedError {
    case invalidBase64
    case aes(Int32)
    case invalidJSON

    var errorDescription: String? {
        switch self {
        case .invalidBase64: "ONE 响应 Base64 无效"
        case .aes(let code): "ONE AES 解密失败 (\(code))"
        case .invalidJSON: "ONE JSON 解析失败"
        }
    }
}

enum OneCrypto {
    private static let aesKey = Data("l*bv%Ziq000Biaog".utf8)
    private static let aesIV = Data("8597506002939249".utf8)

    /// 与 one-web `parseOneResponse` 一致：先尝试明文 JSON，否则 AES-CBC 再 JSON
    static func parseOneResponse(_ text: String) throws -> Data {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let data = trimmed.data(using: .utf8),
           (try? JSONSerialization.jsonObject(with: data)) != nil
        {
            return data
        }
        let plain = try aesDecryptBase64Cipher(trimmed)
        guard let data = plain.data(using: .utf8),
              (try? JSONSerialization.jsonObject(with: data)) != nil
        else {
            throw OneCryptoError.invalidJSON
        }
        return data
    }

    private static func aesDecryptBase64Cipher(_ b64: String) throws -> String {
        var clean = b64.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let pad = clean.count % 4
        if pad != 0 { clean += String(repeating: "=", count: 4 - pad) }
        guard let cipher = Data(base64Encoded: clean) else {
            throw OneCryptoError.invalidBase64
        }
        let plain = try AESCBC.decrypt(cipher: cipher, key: aesKey, iv: aesIV)
        guard let text = String(data: plain, encoding: .utf8) else {
            throw OneCryptoError.invalidJSON
        }
        return text
    }
}
