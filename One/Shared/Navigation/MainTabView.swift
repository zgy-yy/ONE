import SwiftUI

/// 主界面底部 Tab；搜索入口在各页顶栏右侧。
struct MainTabView: View {
    @State private var showsSearch = false

    private func openSearch(_ request: OpenSearchRequest) {
        let session = SearchSession.shared
        if let keyword = request.keyword {
            let text = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                let category = request.category ?? session.category
                session.openSearch(keyword: text, category: category)
            }
        } else if let category = request.category {
            session.category = category
        }
        showsSearch = true
    }

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
        .environment(\.openSearch, openSearch)
        .searchCardSheet(isPresented: $showsSearch)
    }
}

#Preview {
    MainTabView()
}
