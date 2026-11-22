import UIKit

extension UIViewController {
    /// 当前界面上最顶层的控制器（用于 `present` 全屏播放等）。
    @MainActor
    static var topMost: UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes.flatMap(\.windows).first(where: \.isKeyWindow)
            ?? scenes.first?.windows.first
        var current = window?.rootViewController
        while true {
            if let presented = current?.presentedViewController {
                current = presented
            } else if let nav = current as? UINavigationController {
                current = nav.visibleViewController
            } else if let tab = current as? UITabBarController {
                current = tab.selectedViewController
            } else {
                return current
            }
        }
    }
}