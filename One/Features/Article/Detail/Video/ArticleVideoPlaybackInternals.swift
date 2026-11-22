import AVFoundation
import SwiftUI
import UIKit

// MARK: - AVPlayerLayer

struct ArticleVideoPlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspect
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.playerLayer.player = player
    }
}

final class PlayerUIView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }

    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}

// MARK: - 进度回调

final class PlayerPeriodicObserver {
    private let player: AVPlayer
    private var token: Any?

    init(player: AVPlayer, interval: Double, onTick: @escaping (Double) -> Void) {
        self.player = player
        let cm = CMTime(seconds: interval, preferredTimescale: 600)
        token = player.addPeriodicTimeObserver(forInterval: cm, queue: .main) { time in
            onTick(time.cmSeconds)
        }
    }

    func invalidate() {
        if let token {
            player.removeTimeObserver(token)
        }
        token = nil
    }
}

final class PlaybackScrubState {
    var isScrubbing = false
}

extension CMTime {
    var cmSeconds: Double { CMTimeGetSeconds(self) }
}

extension View {
    /// 无衬底时保证图标在画面上可读。
    func playbackControlShadow() -> some View {
        shadow(color: .black.opacity(0.45), radius: 3, x: 0, y: 1)
    }
}