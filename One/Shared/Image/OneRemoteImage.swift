import Foundation
import ImageIO
import UIKit

/// `one_img` CDN：下载 → 必要时 AES 解密；带内存缓存，返回列表时不重复拉图。
enum OneRemoteImage {
    struct Payload {
        let data: Data
        let mimeType: String
        var isGIF: Bool { mimeType == "image/gif" }
    }

    private static let imageCache = NSCache<NSString, UIImage>()
    private static let payloadCache = NSCache<NSString, NSData>()
    private static let listImageCache = NSCache<NSString, UIImage>()
    private static let aspectRatioCache = NSCache<NSString, NSNumber>()

    /// 列表封面已解码过的原图宽高比（宽 / 高），用于 Masonry 占位与减少加载后跳动。
    static func cachedAspectRatio(for path: String) -> CGFloat? {
        guard let value = aspectRatioCache.object(forKey: path as NSString)?.doubleValue, value > 0 else {
            return nil
        }
        return CGFloat(value)
    }

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
            rememberAspectRatio(path: path, data: data)
            return Payload(data: data, mimeType: mimeType(for: data))
        }

        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let urlString: String
        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            urlString = trimmed
        } else {
            guard let base = TokensSession.shared.oneImgCDN, !base.isEmpty else { return nil }
            urlString = OneCDN.join(base: base, path: path)
        }
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
            rememberAspectRatio(path: path, data: imageData)
            return Payload(data: imageData, mimeType: mimeType(for: imageData))
        } catch {
            return nil
        }
    }

    /// 列表静图：下采样解码，避免全尺寸 `UIImage` 占满内存；与 `OneCoverImage` 默认 `maxPixelSize` 一致。
    @MainActor
    static func loadListThumbnail(path: String, maxPixelSize: CGFloat = 960) async -> UIImage? {
        let cacheKey = "\(path)|\(Int(maxPixelSize))" as NSString
        if let cached = listImageCache.object(forKey: cacheKey) {
            return cached
        }
        guard let payload = await loadPayload(path: path), !payload.isGIF else { return nil }
        let image = decodeStillThumbnail(data: payload.data, maxPixelSize: maxPixelSize)
            ?? UIImage(data: payload.data)
        if let image {
            listImageCache.setObject(image, forKey: cacheKey)
        }
        return image
    }

    private static func rememberAspectRatio(path: String, data: Data) {
        guard let size = GIFDecoder.pixelSize(data), size.height > 0 else { return }
        let aspect = size.width / size.height
        aspectRatioCache.setObject(NSNumber(value: Double(aspect)), forKey: path as NSString)
    }

    private static func decodeStillThumbnail(data: Data, maxPixelSize: CGFloat) -> UIImage? {
        let sourceOptions: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions as CFDictionary) else {
            return nil
        }
        let pixelMax = max(1, Int(maxPixelSize))
        let thumbOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: pixelMax,
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbOptions as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
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
