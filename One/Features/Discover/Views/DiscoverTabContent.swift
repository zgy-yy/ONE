import SwiftUI

/// 发现 Tab 根页。
///
/// 各频道列表保活：切走再切回时保留滚动位置（不再用 `.id(channel)` 销毁视图）。
struct DiscoverTabContent: View {
    @Bindable private var session = DiscoverSession.shared
    @State private var channel: DiscoverChannel = .graphic
    /// 只挂载访问过的频道，避免一上来创建 6 份列表。
    @State private var visited: Set<DiscoverChannel> = [.graphic]

    var body: some View {
        NavigationStack {
            ZStack {
                ForEach(DiscoverChannel.allCases.filter { visited.contains($0) }) { item in
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
            .navigationDestination(for: SeriesSummary.self) { series in
                SeriesDetailView(series: series)
            }
            .navigationDestination(for: ArticleSummary.self) { article in
                ArticleDetailView(article: article)
            }
            .onChange(of: channel) { _, newChannel in
                visited.insert(newChannel)
            }
        }
    }
}

#Preview {
    DiscoverTabContent()
}
