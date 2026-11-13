import SwiftUI

/// 主界面底部五个 Tab（iOS 18+ `Tab` + `TabView`）。
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
                OnDemandView()
            }
            SwiftUI.Tab("演员", systemImage: "person.2.fill") {
                ActorTabContent()
            }
            SwiftUI.Tab("我的", systemImage: "person.circle.fill") {
                MineTabContent()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

#Preview {
    MainTabView()
}
