import SwiftUI

/// 发现频道列表：文章按月分段下滑加载更早月；写真 / 漫画为系列扁平列表。
struct DiscoverFeedView: View {
    let channel: ContentCategory
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
            articleList
        }
    }

    private var articleList: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(sections) { section in
                    Section {
                        ForEach(section.articles) { article in
                            articleRow(article)
                                .hiddenNavigationLink(value: article)
                                .styledListRow()
                                .onAppear {
                                    guard sections.isTailArticle(article, in: section) else { return }
                                    Task { await session.loadMoreArticles(channel: channel) }
                                }
                        }
                    } header: {
                        ArticleMonthSectionHeader(monthAPIString: section.month)
                            .id(section.month)
                    }
                }
                Section {
                    AppUI.listLoadMoreFooter(
                        loadingMore: session.isLoadingMoreArticles(channel),
                        exhausted: session.showsArticlesEndFooter(channel)
                    )
                }
            }
            .plainContentList()
            .onChange(of: session.listPublishedAt) { _, month in
                // 锚定月已在列表里则滚过去；否则按新锚定月重载
                if sections.contains(where: { $0.month == month }) {
                    scrollToMonth(month, proxy: proxy)
                } else {
                    Task { await session.loadArticles(channel: channel, force: true) }
                }
            }
        }
    }

    @ViewBuilder
    private func articleRow(_ article: ArticleSummary) -> some View {
        if channel == .film {
            FilmArticleRow(article: article)
        } else {
            VodArticleRow(article: article, fallbackModelID: channel.articleModelID)
        }
    }

    private func scrollToMonth(_ month: String, proxy: ScrollViewProxy) {
        guard sections.contains(where: { $0.month == month }) else { return }
        Task { @MainActor in
            withAnimation(.easeInOut(duration: 0.25)) {
                proxy.scrollTo(month, anchor: .top)
            }
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
