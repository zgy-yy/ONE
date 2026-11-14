import AVFoundation
import Foundation

/// 点播播放前激活音频会话（真机在静音开关下也可出声）。
enum VideoPlaybackAudio {
    private(set) static var isConfigured = false

    static func activate() {
        guard !isConfigured else { return }
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .moviePlayback, options: [])
            try session.setActive(true)
            isConfigured = true
        } catch {
            // 配置失败时仍尝试播放，由系统默认会话处理
        }
    }
}