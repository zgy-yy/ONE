import SwiftUI

/// 发现频道列表：文章 或 写真 / 漫画系列。
struct DiscoverFeedView: View {
    let channel: DiscoverChannel
    @Bindable private var session = DiscoverSession.shared

    private var loadToken: String {
        channel.isSeries
            ? "\(channel.rawValue)-\(session.seriesFeedKey)"
            : "\(channel.rawValue)-\(session.articleFeedKey)"
    }

    var body: some View {
        Group {
            if channel.isSeries {
                seriesPage
            } else {
                articlePage
            }
        }
        .task(id: loadToken) {
            if channel.isSeries {
                await session.loadSeries(channel: channel)
            } else {
                await session.loadArticles(channel: channel)
            }
        }
    }

    // MARK: - 文章

    private var articles: [ArticleSummary] {
        session.articles(for: channel)
    }

    private var articlePage: some View {
        AsyncPage(
            isLoading: session.isLoadingArticles(channel),
            error: session.articleError(for: channel),
            isEmpty: articles.isEmpty,
            loadingTitle: "加载\(channel.title)…",
            emptyTitle: "无内容",
            retry: { Task { await session.loadArticles(channel: channel, force: true) } }
        ) {
            List {
                ForEach(articles) { article in
                    ArticleListRow(article: article, fallbackModelID: channel.articleModelID)
                        .hiddenNavigationLink(value: article)
                        .styledListRow()
                        .onAppear {
                            guard articles.isLastItem(article) else { return }
                            Task { await session.loadMoreArticles(channel: channel) }
                        }
                }
                AppUI.listLoadMoreFooter(
                    loadingMore: session.isLoadingMoreArticles(channel),
                    exhausted: session.showsArticlesEndFooter(channel)
                )
            }
            .plainContentList()
        }
    }

    // MARK: - 系列

    private var seriesItems: [SeriesSummary] {
        session.series(for: channel)
    }

    private var seriesPage: some View {
        AsyncPage(
            isLoading: session.isLoadingSeries(channel),
            error: session.seriesError(for: channel),
            isEmpty: seriesItems.isEmpty,
            loadingTitle: "加载\(channel.title)…",
            emptyTitle: "无内容",
            retry: { Task { await session.loadSeries(channel: channel, force: true) } }
        ) {
            List {
                ForEach(seriesItems) { item in
                    SeriesRow(item: item)
                        .hiddenNavigationLink(value: item)
                        .styledListRow()
                        .onAppear {
                            guard seriesItems.isLastItem(item) else { return }
                            Task { await session.loadMoreSeries(channel: channel) }
                        }
                }
                AppUI.listLoadMoreFooter(
                    loadingMore: session.isLoadingMoreSeries(channel),
                    exhausted: session.showsSeriesEndFooter(channel)
                )
            }
            .plainContentList()
        }
    }
}
