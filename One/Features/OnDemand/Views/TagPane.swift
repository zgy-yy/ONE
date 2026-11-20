import SwiftUI

/// 单个点播分类下的文章列表。
struct TagPane: View {
    let tag: DemandTag
    @Bindable private var session = VodSession.shared

    private var tagID: Int { tag.id }
    private var sections: [ArticleMonthSection] { session.articleSections(for: tagID) }

    @State private var articleDestination: ArticleSummary?

    private var listLoadToken: String {
        "\(tagID)-\(session.articleListTaskKey)"
    }

    private var hasNoArticles: Bool {
        sections.isEmpty || sections.allSatisfy(\.articles.isEmpty)
    }

    var body: some View {
        AsyncPage(
            isLoading: session.isLoadingArticles(tagID: tagID),
            error: session.articleError(for: tagID),
            isEmpty: hasNoArticles,
            loadingTitle: "加载列表…",
            emptyTitle: "无内容",
            retry: { Task { await session.loadArticles(for: tagID, force: true) } }
        ) {
            MonthPagedArticleList(
                sections: sections,
                publishedAt: session.listPublishedAt,
                loadingMore: session.isLoadingMoreArticles(tagID: tagID),
                exhausted: session.showsArticlesEndFooter(tagID: tagID),
                onAnchorMonthMissing: {
                    Task { await session.loadArticles(for: tagID, force: true) }
                }
            ) { section in
                ForEach(section.articles) { article in
                    VodArticleRow(article: article)
                        .styledListRow()
                        .contentShape(Rectangle())
                        .onTapGesture { articleDestination = article }
                        .onAppear {
                            guard sections.isTailArticle(article, in: section) else { return }
                            Task { await session.loadMoreArticles(for: tagID) }
                        }
                }
            }
            .navigationDestination(item: $articleDestination) { article in
                ArticleDetailView(article: article)
            }
        }
        .refreshable {
            await session.pullToRefreshArticles(for: tagID)
        }
        .task(id: listLoadToken) { await session.loadArticles(for: tagID) }
        .onChange(of: session.listPublishedAt) { _, month in
            // 空态不挂载 MonthPagedArticleList，须在此按新锚定月重载。
            guard hasNoArticles || !sections.contains(where: { $0.month == month }) else { return }
            Task { await session.loadArticles(for: tagID, force: true) }
        }
    }
}
