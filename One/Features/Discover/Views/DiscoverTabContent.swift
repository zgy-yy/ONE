import SwiftUI

/// 发现根页面：发布日期 / 排序 + 频道 Tab（图文 / 阅读 / 影视 / 电台）。
struct DiscoverTabContent: View {
    @Bindable private var session = DiscoverSession.shared
    @State private var channel: DiscoverChannel = .graphic

    var body: some View {
        NavigationStack {
            DiscoverFeedView(channel: channel)
                .id("\(channel.rawValue)-\(session.feedFetchKey)")
                .fillPage()
                .navigationTitle("发现")
                .navigationBarTitleDisplayMode(.inline)
                .safeAreaInset(edge: .top, spacing: 0) {
                    DiscoverTopBar(channel: $channel, session: session)
                }
                .navigationDestination(for: ArticleSummary.self) { article in
                    ArticleDetailView(article: article)
                }
        }
    }
}

#Preview {
    DiscoverTabContent()
}
