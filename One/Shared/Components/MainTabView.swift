import SwiftUI

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
