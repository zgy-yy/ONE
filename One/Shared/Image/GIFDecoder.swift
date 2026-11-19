import ImageIO
import UIKit

/// GIF 帧解码 + 内存缓存（列表封面可下采样）。
nonisolated enum GIFDecoder {
    final class Decoded: NSObject, @unchecked Sendable {
        let frames: [UIImage]
        let duration: TimeInterval

        init(frames: [UIImage], duration: TimeInterval) {
            self.frames = frames
            self.duration = duration
        }

        var firstFrame: UIImage? { frames.first }
        var isAnimated: Bool { frames.count > 1 }
    }

    private static let cache = NSCache<NSString, Decoded>()

    nonisolated static func cached(data: Data, maxPixelSize: CGFloat?) -> Decoded? {
        cache.object(forKey: cacheKey(data: data, maxPixelSize: maxPixelSize))
    }

    nonisolated static func pixelSize(_ data: Data) -> CGSize? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return UIImage(data: data)?.size
        }
        let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        if let w = props?[kCGImagePropertyPixelWidth] as? CGFloat,
           let h = props?[kCGImagePropertyPixelHeight] as? CGFloat,
           w > 0, h > 0 {
            return CGSize(width: w, height: h)
        }
        guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
        return CGSize(width: cgImage.width, height: cgImage.height)
    }

    nonisolated static func decode(data: Data, maxPixelSize: CGFloat?) async -> Decoded {
        let key = cacheKey(data: data, maxPixelSize: maxPixelSize)
        if let cached = cache.object(forKey: key) { return cached }

        let decoded = await Task.detached(priority: .userInitiated) {
            Self.decodeSync(data: data, maxPixelSize: maxPixelSize)
        }.value

        cache.setObject(decoded, forKey: key, cost: max(decoded.frames.count, 1) * 64_000)
        return decoded
    }

    nonisolated private static func cacheKey(data: Data, maxPixelSize: CGFloat?) -> NSString {
        let sample = data.prefix(64).reduce(into: "") { $0.append(String(format: "%02x", $1)) }
        return "\(data.count)-\(Int(maxPixelSize ?? 0))-\(sample)" as NSString
    }

    nonisolated private static func decodeSync(data: Data, maxPixelSize: CGFloat?) -> Decoded {
        let createOptions: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let source = CGImageSourceCreateWithData(data as CFData, createOptions as CFDictionary) else {
            return Decoded(frames: UIImage(data: data).map { [$0] } ?? [], duration: 0)
        }

        let count = CGImageSourceGetCount(source)
        var frames: [UIImage] = []
        frames.reserveCapacity(count)
        var duration: TimeInterval = 0
        let thumbOptions = thumbnailOptions(maxPixelSize: maxPixelSize)

        for index in 0 ..< count {
            let cgImage: CGImage?
            if let thumbOptions {
                cgImage = CGImageSourceCreateThumbnailAtIndex(source, index, thumbOptions as CFDictionary)
            } else {
                cgImage = CGImageSourceCreateImageAtIndex(source, index, nil)
            }
            guard let cgImage else { continue }
            frames.append(UIImage(cgImage: cgImage))
            duration += delay(source: source, index: index)
        }

        if frames.count > 1 {
            duration = max(duration, Double(frames.count) * 0.06)
        }
        return Decoded(frames: frames, duration: duration)
    }

    nonisolated private static func thumbnailOptions(maxPixelSize: CGFloat?) -> [CFString: Any]? {
        guard let maxPixelSize, maxPixelSize > 0 else { return nil }
        return [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(maxPixelSize),
        ]
    }

    nonisolated private static func delay(source: CGImageSource, index: Int) -> TimeInterval {
        let props = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any]
        let gif = props?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
        let value =
            (gif?[kCGImagePropertyGIFUnclampedDelayTime] as? NSNumber)?.doubleValue
            ?? (gif?[kCGImagePropertyGIFDelayTime] as? NSNumber)?.doubleValue
            ?? 0.1
        return value < 0.02 ? 0.1 : value
    }
}
