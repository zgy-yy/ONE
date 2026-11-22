import AVFoundation
import CoreGraphics
import Foundation

/// 详情 `quality` 字段（如 `1920x1080`）解析为像素宽高。
enum ArticleVideoDeclaredResolution {
    private static let dimensionPattern = try? NSRegularExpression(
        pattern: #"(\d{3,5})\s*[xX×*＊]\s*(\d{3,5})"#
    )

    static func parse(quality: String?) -> CGSize? {
        guard let raw = quality?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        guard let pattern = dimensionPattern,
              let match = pattern.firstMatch(in: raw, range: NSRange(raw.startIndex..., in: raw)),
              match.numberOfRanges == 3,
              let wRange = Range(match.range(at: 1), in: raw),
              let hRange = Range(match.range(at: 2), in: raw),
              let width = Double(raw[wRange]),
              let height = Double(raw[hRange]),
              width > 0, height > 0
        else { return nil }

        return CGSize(width: width, height: height)
    }

    static func isLandscape(_ size: CGSize) -> Bool {
        size.width > size.height
    }
}

enum ArticleVideoAspect {
    /// 轨道 `naturalSize`（不应用旋转变换，避免把 1920×1080 误判成竖屏）。
    static func encodedSize(for asset: AVAsset) async -> CGSize? {
        guard let track = try? await asset.loadTracks(withMediaType: .video).first else { return nil }
        guard let naturalSize = try? await track.load(.naturalSize) else { return nil }
        let w = abs(naturalSize.width)
        let h = abs(naturalSize.height)
        guard w > 0, h > 0 else { return nil }
        return CGSize(width: w, height: h)
    }

    static func encodedSize(url: URL, maxAttempts: Int = 15) async -> CGSize? {
        let asset = AVURLAsset(url: url)
        for attempt in 0 ..< maxAttempts {
            _ = try? await asset.load(.tracks)
            if let size = await encodedSize(for: asset) { return size }
            try? await Task.sleep(for: .milliseconds(80 + attempt * 40))
        }
        return nil
    }
}

/// 旋转**画面 + 控件**；仅 0° / 90°。
enum PlaybackContentRotation {
    /// 详情分辨率或轨尺寸：**宽 > 高** 且在竖屏容器 → 90°。
    static func autoDegrees(contentSize: CGSize, containerSize: CGSize) -> Double {
        guard containerSize.height >= containerSize.width else { return 0 }
        return ArticleVideoDeclaredResolution.isLandscape(contentSize) ? 90 : 0
    }

    static func isValidPixelSize(_ size: CGSize) -> Bool {
        min(size.width, size.height) >= 64 && max(size.width, size.height) >= 160
    }

    static func toggleDegrees(_ current: Double) -> Double {
        Int(current.rounded()) % 360 == 90 ? 0 : 90
    }

    static func isQuarterTurn(_ degrees: Double) -> Bool {
        Int(degrees.rounded()) % 360 == 90
    }

    static func stageSize(for container: CGSize, rotation: Double) -> CGSize {
        if isQuarterTurn(rotation) {
            return CGSize(width: container.height, height: container.width)
        }
        return container
    }
}