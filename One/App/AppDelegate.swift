import UIKit

/// 播放中允许旋转；其他页面仅竖屏。
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        PlaybackOrientation.supportedMask
    }
}
