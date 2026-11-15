import AVKit
import UIKit

/// 系统 `AVPlayerViewController` 全屏播放；播放中可旋转，关闭后回到竖屏。
enum ArticleVideoPresenter {
    @MainActor
    static func present(url: URL) {
        guard let host = UIViewController.topMost else { return }
        VideoPlaybackAudio.activate()
        PlaybackOrientation.enterPlayer()

        let controller = RotatableAVPlayerViewController()
        let player = AVPlayer(url: url)
        player.isMuted = false
        player.automaticallyWaitsToMinimizeStalling = true
        controller.player = player
        controller.showsPlaybackControls = true
        controller.allowsPictureInPicturePlayback = true
        controller.canStartPictureInPictureAutomaticallyFromInline = false
        controller.modalPresentationStyle = .fullScreen
        controller.isModalInPresentation = true
        host.present(controller, animated: true) {
            player.play()
        }
    }
}

/// 播放页允许竖/横旋转；关闭后强制回竖屏。
private final class RotatableAVPlayerViewController: AVPlayerViewController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .allButUpsideDown }
    override var shouldAutorotate: Bool { true }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        disableContentGestures()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // 在 disappear 后再解锁，确保能可靠请求回竖屏。
        guard isBeingDismissed || presentingViewController == nil else { return }
        player?.pause()
        player = nil
        PlaybackOrientation.exitPlayer()
    }

    private func disableContentGestures() {
        let contentView = (view.value(forKey: "contentView") as? UIView) ?? view
        for gesture in contentView?.gestureRecognizers ?? [] {
            if gesture is UIPanGestureRecognizer
                || gesture is UIPinchGestureRecognizer
                || gesture is UIRotationGestureRecognizer
                || gesture is UISwipeGestureRecognizer
            {
                gesture.isEnabled = false
            }
        }
    }
}

private extension UIViewController {
    static var topMost: UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes.flatMap(\.windows).first(where: \.isKeyWindow)
            ?? scenes.first?.windows.first
        var current = window?.rootViewController
        while true {
            if let presented = current?.presentedViewController {
                current = presented
            } else if let nav = current as? UINavigationController {
                current = nav.visibleViewController
            } else if let tab = current as? UITabBarController {
                current = tab.selectedViewController
            } else {
                return current
            }
        }
    }
}
