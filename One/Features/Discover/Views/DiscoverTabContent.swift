import SwiftUI

/// 发现 Tab 根页。
///
/// 各频道列表保活：切走再切回时保留滚动位置（不再用 `.id(channel)` 销毁视图）。
struct DiscoverTabContent: View {
    @Bindable private var session = DiscoverSession.shared
    @State private var channel: ContentCategory = .graphic
    /// 只挂载访问过的频道，避免一上来创建 6 份列表。
    @State private var visited: Set<ContentCategory> = [.graphic]

    var body: some View {
        NavigationStack {
            ZStack {
                ForEach(ContentCategory.discoverCases.filter { visited.contains($0) }) { item in
                    DiscoverFeedView(channel: item)
                        .opacity(item == channel ? 1 : 0)
                        .allowsHitTesting(item == channel)
                        .accessibilityHidden(item != channel)
                }
            }
            .fillPage()
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                DiscoverTopBar(channel: $channel, session: session)
            }
            .libraryDetailDestinations()
            .onChange(of: channel) { _, newChannel in
                visited.insert(newChannel)
            }
        }
    }
}

#Preview {
    DiscoverTabContent()
}
