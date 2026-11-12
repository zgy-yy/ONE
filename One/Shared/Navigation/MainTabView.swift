import SwiftUI

/// 主界面：底部五个 Tab（iOS 18+ 的 `Tab` + `TabView` API）。
///
/// - 这里写 `SwiftUI.Tab` 是因为点播页自定义了名叫 `Tab` 的 View，避免名字冲突。
/// - 每个 Tab 里放一个子页面（`HomeTabContent`、`Tab` 等）。
struct MainTabView: View {
    var body: some View {
        TabView {
            SwiftUI.Tab("首页", systemImage: "house.fill") {
                HomeTabContent()
            }
            SwiftUI.Tab("发现", systemImage: "safari.fill") {
                DiscoverTabContent()
            }
            SwiftUI.Tab("点播", systemImage: "play.rectangle.fill") {
                Tab()
            }
            SwiftUI.Tab("演员", systemImage: "person.2.fill") {
                ActorTabContent()
            }
            SwiftUI.Tab("我的", systemImage: "person.circle.fill") {
                MineTabContent()
            }
        }
    }
}

#Preview {
    MainTabView()
}
