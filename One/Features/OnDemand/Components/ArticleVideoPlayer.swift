import AVKit
import SwiftUI
import UIKit

/// 全宽 16:9 点播播放器：`AVPlayerViewController` 支持系统全屏与系统控件。
struct ArticleVideoPlayer: View {
    let url: URL

    @State private var player: AVPlayer?

    var body: some View {
        Group {
            if let player {
                InlineAVPlayerViewController(player: player)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(16 / 9, contentMode: .fit)
        .onAppear { startPlayback(url) }
        .onChange(of: url) { _, newURL in startPlayback(newURL) }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    private func startPlayback(_ url: URL) {
        VideoPlaybackAudio.activate()
        player?.pause()
        let newPlayer = AVPlayer(url: url)
        newPlayer.isMuted = false
        newPlayer.automaticallyWaitsToMinimizeStalling = true
        player = newPlayer
        newPlayer.play()
    }
}

private struct InlineAVPlayerViewController: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        controller.allowsPictureInPicturePlayback = true
        controller.canStartPictureInPictureAutomaticallyFromInline = false
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        if controller.player !== player {
            controller.player = player
        }
    }
}