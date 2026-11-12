import CryptoKit
import Foundation
import zlib

/// 壳接口：请求头签名 + 响应 AES/gzip 解压（与 `OneCrypto` 独立）。
enum TokensCryptoError: LocalizedError {
    case invalidBase64
    case aes(Int32)
    case gzip(Int32)
    case invalidJSON
    case emptyBody

    var errorDescription: String? {
        switch self {
        case .invalidBase64: "Tokens 响应 Base64 无效"
        case .aes(let s): "AES 解密失败 (\(s))"
        case .gzip(let s): "gzip 解压失败 (\(s))"
        case .invalidJSON: "JSON 解析失败"
        case .emptyBody: "响应体为空"
        }
    }
}

enum TokensCrypto {
    private static let xorKey: UInt32 = 0x1395

    private static let obfSign =
        "ᎤᏳᎧ᏷Ꭷ᏶ᏱᎥᏳᎬᎠᎥᎦᏳᎬᎣᎥ᏶ᎧᏴᏱᎦᏳᎥᎤᎬᎡ᏷ᎡᎤᎢᎠ"
    private static let obfAESKey = "ᎭᎬᎬᎧᏱᎧᎢ᏷᏶ᏰᏴᏰᎧᎬᎣᎧ"
    private static let obfAESIV = "ᎣᎧᎧᎦᎦᎠᎦᎧᏴ᏶ᎬᎥᎧᎬ᏶Ꭳ"

    private static let signSalt: String = deobfuscateScalars(obfSign)
    private static let aesKey: Data = deobfuscateLatin1(obfAESKey)
    private static let aesIV: Data = deobfuscateLatin1(obfAESIV)

    static func makeRequestHeaders(path: String, timeMs: Int64 = Int64(Date().timeIntervalSince1970 * 1000)) -> [String: String] {
        let plain = ["/", path, String(timeMs), signSalt].joined()
        return [
            "time": String(timeMs),
            "uuid": md5Hex(plain),
        ]
    }

    static func parseResponse(_ text: String) throws -> Data {
        var t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { throw TokensCryptoError.emptyBody }
        if t.hasPrefix("{") || t.hasPrefix("[") {
            guard let data = t.data(using: .utf8) else { throw TokensCryptoError.invalidJSON }
            return data
        }
        t = unwrapJSONString(t)
        let jsonText = try decryptPayload(t)
        guard let data = jsonText.data(using: .utf8) else { throw TokensCryptoError.invalidJSON }
        return data
    }

    private static func deobfuscateScalars(_ value: String) -> String {
        let scalars = value.unicodeScalars.map { UnicodeScalar($0.value ^ xorKey)! }
        return String(String.UnicodeScalarView(scalars))
    }

    private static func deobfuscateLatin1(_ value: String) -> Data {
        Data(value.unicodeScalars.map { UInt8(($0.value ^ xorKey) & 0xff) })
    }

    private static func md5Hex(_ string: String) -> String {
        let digest = Insecure.MD5.hash(data: Data(string.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func unwrapJSONString(_ text: String) -> String {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.hasPrefix("\"") else { return t }
        guard let data = t.data(using: .utf8),
              let parsed = try? JSONDecoder().decode(String.self, from: data)
        else { return t }
        return parsed
    }

    private static func base64ToData(_ b64: String) throws -> Data {
        var clean = b64.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s", with: "", options: .regularExpression)
        clean = clean.replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let pad = clean.count % 4
        if pad != 0 {
            clean += String(repeating: "=", count: 4 - pad)
        }
        guard let data = Data(base64Encoded: clean) else { throw TokensCryptoError.invalidBase64 }
        return data
    }

    private static func aesCBCDecrypt(_ cipher: Data) throws -> Data {
        do {
            return try AESCBC.decrypt(cipher: cipher, key: aesKey, iv: aesIV)
        } catch let error as AESCBCError {
            switch error {
            case .invalidKeyIV: throw TokensCryptoError.aes(-1)
            case .failed(let code): throw TokensCryptoError.aes(code)
            }
        }
    }

    private static func gunzip(_ data: Data) throws -> Data {
        if data.isEmpty { return data }
        return try data.withUnsafeBytes { input in
            guard let base = input.baseAddress?.assumingMemoryBound(to: Bytef.self) else {
                throw TokensCryptoError.gzip(-1)
            }
            var stream = z_stream()
            stream.next_in = UnsafeMutablePointer(mutating: base)
            stream.avail_in = uInt(data.count)
            var status = inflateInit2_(&stream, MAX_WBITS + 32, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
            guard status == Z_OK else { throw TokensCryptoError.gzip(status) }
            defer { inflateEnd(&stream) }

            var output = Data()
            let chunk = 32_768
            var buffer = [UInt8](repeating: 0, count: chunk)
            repeat {
                stream.next_out = UnsafeMutablePointer(mutating: &buffer)
                stream.avail_out = uInt(chunk)
                status = inflate(&stream, Z_SYNC_FLUSH)
                let produced = chunk - Int(stream.avail_out)
                if produced > 0 {
                    output.append(buffer, count: produced)
                }
                if status == Z_STREAM_END { break }
                if status != Z_OK { throw TokensCryptoError.gzip(status) }
            } while stream.avail_out == 0
            return output
        }
    }

    private static func decryptPayload(_ b64: String) throws -> String {
        let cipher = try base64ToData(b64)
        let plain = try aesCBCDecrypt(cipher)
        let unzipped = try gunzip(plain)
        guard let text = String(data: unzipped, encoding: .utf8) else {
            throw TokensCryptoError.invalidJSON
        }
        return text
    }
}
