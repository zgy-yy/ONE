import SwiftUI

/// 主界面底部 Tab；右下角搜索入口，滚动隐藏，点开卡片 sheet。
struct MainTabView: View {
    @State private var showsSearch = false

    var body: some View {
        TabView {
            SwiftUI.Tab("首页", systemImage: "house.fill") {
                HomeTabContent()
                    .withSearchFAB(isPresented: $showsSearch)
            }
            SwiftUI.Tab("发现", systemImage: "safari.fill") {
                DiscoverTabContent()
                    .withSearchFAB(isPresented: $showsSearch)
            }
            SwiftUI.Tab("点播", systemImage: "play.rectangle.fill") {
                VodTabContent()
                    .withSearchFAB(isPresented: $showsSearch)
            }
            SwiftUI.Tab("演员", systemImage: "person.2.fill") {
                ActorTabContent()
                    .withSearchFAB(isPresented: $showsSearch)
            }
            SwiftUI.Tab("我的", systemImage: "person.circle.fill") {
                MineTabContent()
                    .withSearchFAB(isPresented: $showsSearch)
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .searchCardSheet(isPresented: $showsSearch)
    }
}

#Preview {
    MainTabView()
}
