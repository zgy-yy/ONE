import SwiftUI

/// 发现频道列表：文章按月分段下滑加载更早月；写真 / 漫画为系列扁平列表。
struct DiscoverFeedView: View {
    let channel: ContentCategory
    @Bindable private var session = DiscoverSession.shared
    /// List 行用显式跳转（避免切换月份后背景 `NavigationLink` 失效）。
    @State private var articleDestination: ArticleSummary?

    private var loadToken: String {
        channel.isSeries
            ? "\(channel.rawValue)-\(session.seriesFeedKey)"
            : "\(channel.rawValue)-\(session.articleListTaskKey)"
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

    private var sections: [ArticleMonthSection] {
        session.articleSections(for: channel)
    }

    private var hasNoArticles: Bool {
        sections.isEmpty || sections.allSatisfy(\.articles.isEmpty)
    }

    private var articlePage: some View {
        AsyncPage(
            isLoading: session.isLoadingArticles(channel),
            error: session.articleError(for: channel),
            isEmpty: hasNoArticles,
            loadingTitle: "加载\(channel.title)…",
            emptyTitle: "无内容",
            retry: { Task { await session.loadArticles(channel: channel, force: true) } }
        ) {
            MonthPagedArticleList(
                sections: sections,
                publishedAt: session.listPublishedAt,
                loadingMore: session.isLoadingMoreArticles(channel),
                exhausted: session.showsArticlesEndFooter(channel),
                onAnchorMonthMissing: {
                    Task { await session.loadArticles(channel: channel, force: true) }
                }
            ) { section in
                if channel == .graphic {
                    graphicRows(section)
                } else {
                    ForEach(section.articles) { article in
                        articleRow(article)
                            .styledListRow()
                            .contentShape(Rectangle())
                            .onTapGesture { articleDestination = article }
                            .onAppear {
                                guard sections.isTailArticle(article, in: section) else { return }
                                Task { await session.loadMoreArticles(channel: channel) }
                            }
                    }
                }
            }
            .navigationDestination(item: $articleDestination) { article in
                ArticleDetailView(article: article)
            }
        }
        .refreshable {
            await session.pullToRefreshArticles(channel: channel)
        }
        .onChange(of: session.listPublishedAt) { _, month in
            guard hasNoArticles || !sections.contains(where: { $0.month == month }) else { return }
            Task { await session.loadArticles(channel: channel, force: true) }
        }
    }

    /// 图文两列瀑布流（与首页月列表 `MasonryLayout` 一致）。
    private func graphicRows(_ section: ArticleMonthSection) -> some View {
        MasonryLayout(columns: 2, spacing: 10) {
            ForEach(section.articles) { article in
                GraphicArticleCard(article: article, textAlignment: .leading)
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                    .onTapGesture { articleDestination = article }
                    .onAppear {
                        guard sections.isTailArticle(article, in: section) else { return }
                        Task { await session.loadMoreArticles(channel: channel) }
                    }
            }
        }
        .styledListRow()
    }

    @ViewBuilder
    private func articleRow(_ article: ArticleSummary) -> some View {
        switch channel {
        case .film:
            FilmArticleRow(article: article)
        case .reading:
            ReadingArticleRow(article: article)
        case .radio:
            RadioArticleRow(article: article)
        default:
            VodArticleRow(article: article, aspectRatio: channel.coverAspect)
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
            .plainContentList {
                await session.loadSeries(channel: channel, force: true)
            }
        }
    }
}
