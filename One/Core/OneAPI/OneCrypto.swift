import CommonCrypto
import CryptoKit
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
    static let uuid = "9b1a29f0-cf81-11f1-92c4-114a8eafec4b"
    static let signSalt = "m4n2hjPeYWkD6tFpqKF^3HO^h24P@idT"
    static let appVersion = "2.6.4"
    static let platform = "6"

    private static let aesKey = Data("l*bv%Ziq000Biaog".utf8)
    private static let aesIV = Data("8597506002939249".utf8)

    /// 与 `one_client.ts` `makeOneHeaders` 一致
    static func makeRequestHeaders(token: String, timestampSec: Int? = nil) -> [String: String] {
        let ts = timestampSec ?? Int(Date().timeIntervalSince1970)
        return [
            "uuid": uuid,
            "user-key": "",
            "timestamp": String(ts),
            "platform": platform,
            "ip": "0.0.0.0",
            "app-version": appVersion,
            "sign": makeSign(timestampSec: ts),
            "token": token,
            "Content-Type": "application/x-www-form-urlencoded",
        ]
    }

    static func makeSign(timestampSec: Int, platform: String = OneCrypto.platform) -> String {
        let s1 = "0.0.0.0.\(platform).\(timestampSec)..\(uuid)"
        let d1 = md5Hex(s1)
        return md5Hex(d1 + signSalt)
    }

    /// POST body：`key=value&…` 排序后 AES-128-CBC → Base64
    static func encryptMapBody(_ data: [String: String]) throws -> String {
        let body = data.keys.sorted().compactMap { key -> String? in
            guard let value = data[key] else { return nil }
            return "\(key)=\(value)"
        }
        .joined(separator: "&")
        let cipher = try AESCBC.encrypt(plain: Data(body.utf8), key: aesKey, iv: aesIV)
        return cipher.base64EncodedString()
    }

    static func md5Hex(_ string: String) -> String {
        let digest = Insecure.MD5.hash(data: Data(string.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

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
