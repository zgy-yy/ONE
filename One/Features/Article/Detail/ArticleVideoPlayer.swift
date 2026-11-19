import AVKit
import UIKit

/// 系统 `AVPlayerViewController` 全屏播放（方向跟随系统）。
enum ArticleVideoPresenter {
    @MainActor
    static func present(url: URL) {
        guard let host = UIViewController.topMost else { return }
        VideoPlaybackAudio.activate()

        let controller = PlaybackAVPlayerViewController()
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

private final class PlaybackAVPlayerViewController: AVPlayerViewController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .allButUpsideDown }
    override var shouldAutorotate: Bool { true }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        disableContentGestures()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard isBeingDismissed || presentingViewController == nil else { return }
        player?.pause()
        player = nil
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
