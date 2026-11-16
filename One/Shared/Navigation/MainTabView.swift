import SwiftUI

/// 主界面底部 Tab；搜索入口在各页顶栏右侧。
struct MainTabView: View {
    @State private var showsSearch = false

    var body: some View {
        TabView {
            SwiftUI.Tab("首页", systemImage: "house.fill") {
                HomeTabContent()
            }
            SwiftUI.Tab("发现", systemImage: "safari.fill") {
                DiscoverTabContent()
            }
            SwiftUI.Tab("点播", systemImage: "play.rectangle.fill") {
                VodTabContent()
            }
            SwiftUI.Tab("演员", systemImage: "person.2.fill") {
                ActorTabContent()
            }
            SwiftUI.Tab("我的", systemImage: "person.circle.fill") {
                MineTabContent()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .environment(\.openSearch) { showsSearch = true }
        .searchCardSheet(isPresented: $showsSearch)
    }
}

#Preview {
    MainTabView()
}
