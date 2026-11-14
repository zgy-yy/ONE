import UIKit

/// 播放页允许旋转；其余页面锁定竖屏，避免退出播放后仍停在横屏。
enum PlaybackOrientation {
    @MainActor
    private(set) static var isPlayerActive = false

    @MainActor
    static var supportedMask: UIInterfaceOrientationMask {
        isPlayerActive ? .allButUpsideDown : .portrait
    }

    /// 进入播放：允许竖屏/横屏随设备旋转。
    @MainActor
    static func enterPlayer() {
        isPlayerActive = true
    }

    /// 离开播放：恢复竖屏并请求系统切回竖屏。
    @MainActor
    static func exitPlayer() {
        guard isPlayerActive else { return }
        isPlayerActive = false
        request(.portrait)
    }

    @MainActor
    private static func request(_ mask: UIInterfaceOrientationMask) {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first else {
            return
        }
        scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask)) { _ in }
        // 让窗口重新询问 AppDelegate 的方向掩码。
        scene.windows.forEach { $0.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations() }
    }
}
