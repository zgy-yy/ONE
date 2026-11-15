import SwiftUI

/// 发现 Tab 根页。
struct DiscoverTabContent: View {
    @Bindable private var session = DiscoverSession.shared
    @State private var channel: DiscoverChannel = .graphic

    var body: some View {
        NavigationStack {
            DiscoverFeedView(channel: channel)
                .id(loadToken)
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
        }
    }

    private var loadToken: String {
        channel.isSeries
            ? "\(channel.rawValue)-\(session.seriesFeedKey)"
            : "\(channel.rawValue)-\(session.articleFeedKey)"
    }
}

#Preview {
    DiscoverTabContent()
}
