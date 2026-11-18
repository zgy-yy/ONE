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

    func makeUIView(context: Context) -> GIFAnimatingImageView {
        let view = GIFAnimatingImageView()
        view.clipsToBounds = true
        // 列表行在 NavigationLink 里点按时不要拦截手势，交给外层跳转。
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: GIFAnimatingImageView, context: Context) {
        view.contentMode = contentMode
        guard context.coordinator.data != data else {
            view.resumeAnimatingIfNeeded()
            return
        }
        context.coordinator.data = data
        view.applyGIF(data)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: GIFAnimatingImageView, context: Context) -> CGSize? {
        if fillsContainer {
            let width = proposal.width ?? uiView.bounds.width
            let height = proposal.height ?? uiView.bounds.height
            guard width > 0, height > 0 else { return nil }
            return CGSize(width: width, height: height)
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
}

/// 用 `animatedImage` 播放，避免 List / NavigationLink 里 `animationImages` 未布局就 start 导致空白，要点一下才出图。
final class GIFAnimatingImageView: UIImageView {
    private var animatedGIF: UIImage?

    override var isHighlighted: Bool {
        get { false }
        set {
            // 丢弃高亮，避免点按后换成 highlightedImage、动图消失。
            resumeAnimatingIfNeeded()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, bounds.height > 0 else { return }
        resumeAnimatingIfNeeded()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        resumeAnimatingIfNeeded()
    }

    func applyGIF(_ data: Data) {
        stopAnimating()
        animationImages = nil
        animatedGIF = nil
        image = nil

        let (frames, duration) = Self.decode(data)
        guard !frames.isEmpty else {
            image = UIImage(data: data)
            return
        }
        guard frames.count > 1 else {
            image = frames[0]
            return
        }

        let animated = UIImage.animatedImage(with: frames, duration: duration)
        animatedGIF = animated
        // 先挂首帧，再设 animatedImage，避免中间空白。
        image = frames[0]
        image = animated
    }

    func resumeAnimatingIfNeeded() {
        guard let animatedGIF else { return }
        if image !== animatedGIF {
            image = animatedGIF
        }
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
