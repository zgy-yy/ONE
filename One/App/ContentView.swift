import SwiftUI

/// 根视图：在「启动页」和「主 Tab 界面」之间切换。
///
/// - `@State`：只属于当前 View 的局部状态；变化时 SwiftUI 会重新调用 `body` 刷新界面。
/// - `@Binding`：把状态「传下去」给子 View，子 View 可以改，父 View 跟着变（见 `EntryView` 的 `enteredMain`）。
struct ContentView: View {
    /// `false` 显示启动页；`true` 显示底部五个 Tab。
    @State private var enteredMain = false

    var body: some View {
        Group {
            if enteredMain {
                MainTabView()
            } else {
                EntryView(enteredMain: $enteredMain)
            }
        }
    }
}

#Preview {
    ContentView()
}
