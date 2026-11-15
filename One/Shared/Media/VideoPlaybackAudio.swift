import AVFoundation
import Foundation

/// 点播播放前激活音频会话（真机在静音开关下也可出声）。
///
/// 不在主线程同步 `setActive`（会卡住 UI）；放到后台队列完成。
enum VideoPlaybackAudio {
    private final class State: @unchecked Sendable {
        let lock = NSLock()
        var isConfigured = false
        var isActivating = false
    }

    private static let state = State()

    static func activate() {
        state.lock.lock()
        let shouldStart = !state.isConfigured && !state.isActivating
        if shouldStart { state.isActivating = true }
        state.lock.unlock()
        guard shouldStart else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(.playback, mode: .moviePlayback, options: [])
                try session.setActive(true)
                state.lock.lock()
                state.isConfigured = true
                state.isActivating = false
                state.lock.unlock()
            } catch {
                // 配置失败时仍尝试播放，由系统默认会话处理
                state.lock.lock()
                state.isActivating = false
                state.lock.unlock()
            }
        }
    }
}
