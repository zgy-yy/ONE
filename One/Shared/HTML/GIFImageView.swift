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
        return view
    }

    func updateUIView(_ view: UIImageView, context: Context) {
        view.image = Self.animatedImage(from: data)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIImageView, context: Context) -> CGSize? {
        let width = proposal.width ?? proposal.replacingUnspecifiedDimensions().width
        guard width > 0, width.isFinite else { return nil }
        guard let pixel = Self.pixelSize(data: data), pixel.width > 0 else {
            return CGSize(width: width, height: width)
        }
        let height = width * pixel.height / pixel.width
        return CGSize(width: width, height: height)
    }

    /// 首帧像素尺寸（布局用）。
    static func pixelSize(data: Data) -> CGSize? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetCount(source) > 0,
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            guard let image = UIImage(data: data), image.size.width > 0 else { return nil }
            return image.size
        }
        return CGSize(width: cgImage.width, height: cgImage.height)
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