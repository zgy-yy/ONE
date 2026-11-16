import ImageIO
import SwiftUI
import UIKit

/// `UIImageView` + ImageIO 播放 GIF。
struct GIFImageView: UIViewRepresentable {
    let data: Data
    var contentMode: UIView.ContentMode = .scaleAspectFit
    /// 定框封面：吃满父视图，不按 GIF 固有比例撑高。
    var fillsContainer: Bool = false

    final class Coordinator { var data: Data? }
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIImageView {
        let view = UIImageView()
        view.clipsToBounds = true
        return view
    }

    func updateUIView(_ view: UIImageView, context: Context) {
        view.contentMode = contentMode
        guard context.coordinator.data != data else {
            if view.animationImages != nil, !view.isAnimating { view.startAnimating() }
            return
        }
        context.coordinator.data = data

        view.stopAnimating()
        view.animationImages = nil
        let (frames, duration) = Self.decode(data)
        guard frames.count > 1 else {
            view.image = frames.first ?? UIImage(data: data)
            return
        }
        view.image = frames[0]
        view.animationImages = frames
        view.animationDuration = duration
        view.animationRepeatCount = 0
        view.startAnimating()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIImageView, context: Context) -> CGSize? {
        if fillsContainer {
            guard let w = proposal.width, let h = proposal.height, w > 0, h > 0 else { return nil }
            return CGSize(width: w, height: h)
        }
        let width = proposal.width ?? proposal.replacingUnspecifiedDimensions().width
        guard width > 0, width.isFinite else { return nil }
        guard let pixel = Self.pixelSize(data), pixel.width > 0 else {
            return CGSize(width: width, height: width)
        }
        return CGSize(width: width, height: width * pixel.height / pixel.width)
    }

    private static func pixelSize(_ data: Data) -> CGSize? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            return UIImage(data: data)?.size
        }
        return CGSize(width: cgImage.width, height: cgImage.height)
    }

    private static func decode(_ data: Data) -> (frames: [UIImage], duration: TimeInterval) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return ([], 0) }
        let count = CGImageSourceGetCount(source)
        var frames: [UIImage] = []
        var duration: TimeInterval = 0
        for index in 0 ..< count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else { continue }
            frames.append(UIImage(cgImage: cgImage))
            duration += delay(source: source, index: index)
        }
        if frames.count > 1 {
            duration = max(duration, Double(frames.count) * 0.06)
        }
        return (frames, duration)
    }

    private static func delay(source: CGImageSource, index: Int) -> TimeInterval {
        let props = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any]
        let gif = props?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
        let value =
            (gif?[kCGImagePropertyGIFUnclampedDelayTime] as? NSNumber)?.doubleValue
            ?? (gif?[kCGImagePropertyGIFDelayTime] as? NSNumber)?.doubleValue
            ?? 0.1
        return value < 0.02 ? 0.1 : value
    }
}
