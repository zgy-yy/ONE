import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("首页", systemImage: "house.fill") {
                HomeTabContent()
            }
            Tab("影视", systemImage: "film.fill") {
                FilmTabContent()
            }
            Tab("点播", systemImage: "play.rectangle.fill") {
                OnDemandTabContent()
            }
        }
    }
}

#Preview {
    MainTabView()
}
