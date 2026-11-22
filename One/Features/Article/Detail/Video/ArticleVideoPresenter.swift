import AVKit
import UIKit

/// 全屏打开文章内链视频（详情页点「播放」）— 使用系统 `AVPlayerViewController`。
enum ArticleVideoPresenter {
    @MainActor
    static func present(url: URL) {
        guard let host = UIViewController.topMost else { return }

        VideoPlaybackAudio.prepareForPlayback()

        let player = AVPlayer(url: url)
        player.isMuted = false
        let controller = AVPlayerViewController()
        controller.player = player
        controller.modalPresentationStyle = .fullScreen
        controller.allowsPictureInPicturePlayback = true
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        controller.exitsFullScreenWhenPlaybackEnds = true

        host.present(controller, animated: true) {
            player.play()
        }
    }
}