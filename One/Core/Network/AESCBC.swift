import CommonCrypto
import Foundation

enum AESCBCError: LocalizedError {
    case invalidKeyIV
    case failed(Int32)

    var errorDescription: String? {
        switch self {
        case .invalidKeyIV: "AES 密钥或 IV 长度无效"
        case .failed(let code): "AES 解密失败 (\(code))"
        }
    }
}

enum AESCBC {
    static func encrypt(plain: Data, key: Data, iv: Data) throws -> Data {
        let keyLength = key.count
        guard keyLength == kCCKeySizeAES128 || keyLength == kCCKeySizeAES192 || keyLength == kCCKeySizeAES256,
              iv.count == kCCBlockSizeAES128
        else {
            throw AESCBCError.invalidKeyIV
        }
        let dataLength = plain.count
        let bufferSize = dataLength + kCCBlockSizeAES128
        var buffer = Data(count: bufferSize)
        var numBytesEncrypted: size_t = 0
        let status = buffer.withUnsafeMutableBytes { bufferBytes in
            plain.withUnsafeBytes { plainBytes in
                key.withUnsafeBytes { keyBytes in
                    iv.withUnsafeBytes { ivBytes in
                        CCCrypt(
                            CCOperation(kCCEncrypt),
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.baseAddress, keyLength,
                            ivBytes.baseAddress,
                            plainBytes.baseAddress, dataLength,
                            bufferBytes.baseAddress, bufferSize,
                            &numBytesEncrypted
                        )
                    }
                }
            }
        }
        guard status == kCCSuccess else { throw AESCBCError.failed(status) }
        return buffer.prefix(numBytesEncrypted)
    }

    static func decrypt(cipher: Data, key: Data, iv: Data) throws -> Data {
        let keyLength = key.count
        guard keyLength == kCCKeySizeAES128 || keyLength == kCCKeySizeAES192 || keyLength == kCCKeySizeAES256,
              iv.count == kCCBlockSizeAES128
        else {
            throw AESCBCError.invalidKeyIV
        }
        let dataLength = cipher.count
        let bufferSize = dataLength + kCCBlockSizeAES128
        var buffer = Data(count: bufferSize)
        var numBytesDecrypted: size_t = 0
        let status = buffer.withUnsafeMutableBytes { bufferBytes in
            cipher.withUnsafeBytes { cipherBytes in
                key.withUnsafeBytes { keyBytes in
                    iv.withUnsafeBytes { ivBytes in
                        CCCrypt(
                            CCOperation(kCCDecrypt),
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.baseAddress, keyLength,
                            ivBytes.baseAddress,
                            cipherBytes.baseAddress, dataLength,
                            bufferBytes.baseAddress, bufferSize,
                            &numBytesDecrypted
                        )
                    }
                }
            }
        }
        guard status == kCCSuccess else { throw AESCBCError.failed(status) }
        return buffer.prefix(numBytesDecrypted)
    }
}
