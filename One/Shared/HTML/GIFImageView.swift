import ImageIO
import SwiftUI
import UIKit

/// 系统 `UIImageView` + ImageIO 播放 GIF（无 WebView）。
struct GIFImageView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> UIImageView {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }

    func updateUIView(_ view: UIImageView, context: Context) {
        view.image = Self.animatedImage(from: data)
    }

    private static func animatedImage(from data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return UIImage(data: data)
        }
        let count = CGImageSourceGetCount(source)
        guard count > 1 else { return UIImage(data: data) }

        var frames: [UIImage] = []
        var duration: TimeInterval = 0

        for index in 0 ..< count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else { continue }
            frames.append(UIImage(cgImage: cgImage))

            let props = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any]
            let gifInfo = props?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
            let delay = gifInfo?[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval
                ?? gifInfo?[kCGImagePropertyGIFDelayTime] as? TimeInterval
                ?? 0.1
            duration += max(delay, 0.02)
        }

        guard !frames.isEmpty else { return UIImage(data: data) }
        return UIImage.animatedImage(with: frames, duration: duration)
    }
}