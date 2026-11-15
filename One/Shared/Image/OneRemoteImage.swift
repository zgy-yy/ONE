import Foundation
import UIKit

/// `one_img` CDN：下载 → 必要时 AES 解密；带内存缓存，返回列表时不重复拉图。
enum OneRemoteImage {
    struct Payload {
        let data: Data
        let mimeType: String
    }

    private static let imageCache = NSCache<NSString, UIImage>()
    private static let payloadCache = NSCache<NSString, NSData>()

    @MainActor
    static func load(path: String) async -> UIImage? {
        let key = path as NSString
        if let cached = imageCache.object(forKey: key) {
            return cached
        }
        guard let payload = await loadPayload(path: path) else { return nil }
        let image = UIImage(data: payload.data)
        if let image {
            imageCache.setObject(image, forKey: key)
        }
        return image
    }

    @MainActor
    static func loadPayload(path: String) async -> Payload? {
        let key = path as NSString
        if let cached = payloadCache.object(forKey: key) {
            let data = cached as Data
            return Payload(data: data, mimeType: mimeType(for: data))
        }

        guard let base = TokensSession.shared.oneImgCDN, !base.isEmpty else { return nil }
        let urlString = OneCDN.join(base: base, path: path)
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let imageData: Data
            if OneImageCrypto.isPlainImage(data) {
                imageData = data
            } else {
                imageData = try OneImageCrypto.decrypt(cipher: data)
            }
            payloadCache.setObject(imageData as NSData, forKey: key)
            return Payload(data: imageData, mimeType: mimeType(for: imageData))
        } catch {
            return nil
        }
    }

    private static func mimeType(for data: Data) -> String {
        let bytes = [UInt8](data.prefix(12))
        if bytes.count >= 3, bytes[0] == 0x47, bytes[1] == 0x49, bytes[2] == 0x46 { return "image/gif" }
        if bytes.count >= 3, bytes[0] == 0xff, bytes[1] == 0xd8 { return "image/jpeg" }
        if bytes.count >= 4, bytes[0] == 0x89, bytes[1] == 0x50, bytes[2] == 0x4e { return "image/png" }
        if bytes.count >= 12, bytes[0] == 0x52, bytes[1] == 0x49, bytes[8] == 0x57, bytes[9] == 0x45 { return "image/webp" }
        return "application/octet-stream"
    }
}
