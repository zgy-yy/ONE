import SwiftUI
import UIKit

/// `UIImageView` + ImageIO 播放 GIF；列表离屏 / 高亮后可恢复动画。
struct GIFImageView: UIViewRepresentable {
    let data: Data
    var contentMode: UIView.ContentMode = .scaleAspectFit
    /// 定框封面：吃满父视图，不按 GIF 固有比例撑高。
    var fillsContainer: Bool = false
    /// 单边最大像素；列表封面传较小值，降低内存。
    var maxPixelSize: CGFloat? = nil

    final class Coordinator {
        var data: Data?
        var decodeTask: Task<Void, Never>?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> GIFAnimatingImageView {
        let view = GIFAnimatingImageView(frame: .zero)
        view.clipsToBounds = true
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
        context.coordinator.decodeTask?.cancel()

        if let cached = GIFDecoder.cached(data: data, maxPixelSize: maxPixelSize) {
            view.apply(cached)
            return
        }
        view.clearContent()

        let data = data
        let maxPixelSize = maxPixelSize
        context.coordinator.decodeTask = Task {
            let decoded = await GIFDecoder.decode(data: data, maxPixelSize: maxPixelSize)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard context.coordinator.data == data else { return }
                view.apply(decoded)
            }
        }
    }

    static func dismantleUIView(_ uiView: GIFAnimatingImageView, coordinator: Coordinator) {
        coordinator.decodeTask?.cancel()
        uiView.clearContent()
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
        guard let pixel = GIFDecoder.pixelSize(data), pixel.width > 0 else {
            return CGSize(width: width, height: width)
        }
        return CGSize(width: width, height: width * pixel.height / pixel.width)
    }
}

/// `animationImages` + 显式 `startAnimating`，避免 List 回收后停帧。
final class GIFAnimatingImageView: UIImageView {
    private var decoded: GIFDecoder.Decoded?
    private var becomeActiveObserver: NSObjectProtocol?

    override init(frame: CGRect) {
        super.init(frame: frame)
        becomeActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.resumeAnimatingIfNeeded()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    deinit {
        if let becomeActiveObserver {
            NotificationCenter.default.removeObserver(becomeActiveObserver)
        }
    }

    override var isHighlighted: Bool {
        get { false }
        set { resumeAnimatingIfNeeded() }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        resumeAnimatingIfNeeded()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        resumeAnimatingIfNeeded()
    }

    func apply(_ decoded: GIFDecoder.Decoded) {
        self.decoded = decoded
        stopAnimating()
        animationImages = nil

        guard let first = decoded.firstFrame else {
            image = nil
            return
        }
        image = first
        guard decoded.isAnimated else { return }
        animationImages = decoded.frames
        animationDuration = decoded.duration
        animationRepeatCount = 0
        resumeAnimatingIfNeeded()
    }

    func resumeAnimatingIfNeeded() {
        guard window != nil, bounds.width > 0, bounds.height > 0 else { return }
        guard let decoded, decoded.isAnimated else { return }

        if animationImages == nil {
            animationImages = decoded.frames
            animationDuration = decoded.duration
            animationRepeatCount = 0
        }
        if image == nil {
            image = decoded.firstFrame
        }
        if !isAnimating {
            startAnimating()
        }
    }

    func clearContent() {
        stopAnimating()
        animationImages = nil
        decoded = nil
        image = nil
    }
}
