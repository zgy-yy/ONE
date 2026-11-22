import AVFoundation

/// 点播 / 全屏播放前配置 `AVAudioSession`。
///
/// 未设为 `.playback` 时，系统往往走 `ambient`，侧边静音键一开就没声。
enum VideoPlaybackAudio {
    /// 在 `AVPlayer.play()` 之前调用（主线程，很快）。
    @MainActor
    static func prepareForPlayback() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .moviePlayback, options: [])
            try session.setActive(true)
        } catch {
            // 失败时仍尝试播放，由系统默认行为处理
        }
    }
}