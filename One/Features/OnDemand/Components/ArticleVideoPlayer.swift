import AVKit
import SwiftUI

/// 全宽 16:9 播放器；`AVPlayer` 放在 `@State` 里，避免界面刷新时反复创建。
struct ArticleVideoPlayer: View {
    let url: URL

    @State private var player: AVPlayer?

    var body: some View {
        Group {
            if let player {
                VideoPlayer(player: player)
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
        player?.pause()
        player = AVPlayer(url: url)
    }
}
