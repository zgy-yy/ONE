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
        .fillPage()
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

    @ViewBuilder
    private var articlePage: some View {
        if session.isLoadingArticles(channel), articles.isEmpty {
            AppUI.loading("加载\(channel.title)…")
        } else if let error = session.articleError(for: channel), articles.isEmpty {
            AppUI.loadFailure(message: error) {
                Task { await session.loadArticles(channel: channel, force: true) }
            }
        } else if articles.isEmpty {
            AppUI.emptyState(icon: "circle.slash", title: "无内容")
        } else {
            List {
                ForEach(articles) { article in
                    articleRow(article)
                        .hiddenNavigationLink(value: article)
                        .styledListRow()
                        .onAppear {
                            guard articles.last?.id == article.id else { return }
                            Task { await session.loadMoreArticles(channel: channel) }
                        }
                }
                AppUI.listLoadMoreFooter(
                    loadingMore: session.isLoadingMoreArticles(channel),
                    exhausted: session.showsArticlesEndFooter(channel)
                )
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private func articleRow(_ article: ArticleSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            OneCoverImage(path: article.thumb)
            article.rowMeta
        }
        .padding(.vertical, 4)
    }

    // MARK: - 系列

    private var seriesItems: [SeriesSummary] {
        session.series(for: channel)
    }

    @ViewBuilder
    private var seriesPage: some View {
        if session.isLoadingSeries(channel), seriesItems.isEmpty {
            AppUI.loading("加载\(channel.title)…")
        } else if let error = session.seriesError(for: channel), seriesItems.isEmpty {
            AppUI.loadFailure(message: error) {
                Task { await session.loadSeries(channel: channel, force: true) }
            }
        } else if seriesItems.isEmpty {
            AppUI.emptyState(icon: "circle.slash", title: "无内容")
        } else {
            List {
                ForEach(seriesItems) { item in
                    SeriesRow(item: item)
                        .hiddenNavigationLink(value: item)
                        .styledListRow()
                        .onAppear {
                            guard seriesItems.last?.id == item.id else { return }
                            Task { await session.loadMoreSeries(channel: channel) }
                        }
                }
                AppUI.listLoadMoreFooter(
                    loadingMore: session.isLoadingMoreSeries(channel),
                    exhausted: session.showsSeriesEndFooter(channel)
                )
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
}
