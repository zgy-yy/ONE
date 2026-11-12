import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("首页", systemImage: "house.fill") {
                HomeTabContent()
            }
            Tab("发现", systemImage: "safari.fill") {
                DiscoverTabContent()
            }
            Tab("点播", systemImage: "play.rectangle.fill") {
                OnDemandTabContent()
            }
            Tab("演员", systemImage: "person.2.fill") {
                ActorTabContent()
            }
            Tab("我的", systemImage: "person.circle.fill") {
                MineTabContent()
            }
        }
    }
}

#Preview {
    MainTabView()
}
