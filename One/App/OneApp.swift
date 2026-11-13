import SwiftUI

/// 应用程序入口。
///
/// - `@main`：标记这是 App 的启动点（类似其他语言的 `main` 函数）。
/// - `App` 协议：描述应用有哪些窗口/场景；`body` 返回 `Scene`。
/// - `WindowGroup`：iOS 上通常就一个全屏窗口，根视图是 `ContentView`。
@main
struct OneApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
