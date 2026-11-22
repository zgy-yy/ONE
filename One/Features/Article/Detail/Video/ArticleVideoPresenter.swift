import SwiftUI
import UIKit

/// 全屏打开文章内链视频（详情页点「播放」）。
enum ArticleVideoPresenter {
    @MainActor
    static func present(url: URL, quality: String? = nil) {
        guard let host = UIViewController.topMost else { return }

        let controller = PortraitFullScreenHostingController(
            rootView: ArticleVideoPlaybackView(url: url, quality: quality)
        )
        controller.modalPresentationStyle = .fullScreen
        host.present(controller, animated: true)
    }
}

/// 播放页锁定竖屏；横片在 `ArticleVideoPlaybackView` 内 `rotationEffect` 转 90°。
private final class PortraitFullScreenHostingController<Content: View>: UIHostingController<Content> {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    override var shouldAutorotate: Bool { false }
    override var prefersStatusBarHidden: Bool { true }
}