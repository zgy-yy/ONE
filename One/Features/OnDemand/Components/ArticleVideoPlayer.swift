import AVKit
import SwiftUI

/// 稳定持有 `AVPlayer`，避免 `body` 重绘时重复创建。
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
        .aspectRatio(16 / 9, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onAppear { replacePlayer(with: url) }
            .onChange(of: url) { _, newURL in
                replacePlayer(with: newURL)
            }
            .onDisappear {
                player?.pause()
                player = nil
            }
    }

    private func replacePlayer(with url: URL) {
        player?.pause()
        player = AVPlayer(url: url)
    }
}
