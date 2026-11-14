import Foundation
import UIKit

/// `one_img` CDN：下载 → 必要时 AES 解密 → 返回图片字节（列表封面、HTML 内图、GIF 共用）。
enum OneRemoteImage {
    struct Payload {
        let data: Data
        let mimeType: String
    }

    @MainActor
    static func load(path: String) async -> UIImage? {
        guard let payload = await loadPayload(path: path) else { return nil }
        return UIImage(data: payload.data)
    }

    @MainActor
    static func loadPayload(path: String) async -> Payload? {
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