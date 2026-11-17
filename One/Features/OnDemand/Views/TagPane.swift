import SwiftUI

/// 单个点播分类下的文章列表。
struct TagPane: View {
    let tag: DemandTag
    @Bindable private var session = VodSession.shared

    private var tagID: Int { tag.id }
    private var sections: [ArticleMonthSection] { session.articleSections(for: tagID) }

    private var listLoadToken: String {
        "\(tagID)-\(session.articleFeedKey)"
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
            articleList
        }
        .task(id: listLoadToken) { await session.loadArticles(for: tagID) }
    }

    private var articleList: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(sections) { section in
                    Section {
                        ForEach(section.articles) { article in
                            VodArticleRow(article: article)
                                .hiddenNavigationLink(value: article)
                                .styledListRow()
                                .onAppear {
                                    guard sections.isTailArticle(article, in: section) else { return }
                                    Task { await session.loadMoreArticles(for: tagID) }
                                }
                        }
                    } header: {
                        ArticleMonthSectionHeader(monthAPIString: section.month)
                            .id(section.month)
                    }
                }
                Section {
                    listFooter
                }
            }
            .plainContentList()
            .onChange(of: session.listPublishedAt) { _, month in
                // 仅月份筛选变化时跳转；下滑加载更多不要滚回顶部。
                if sections.contains(where: { $0.month == month }) {
                    scrollToMonth(month, proxy: proxy)
                } else {
                    Task { await session.loadArticles(for: tagID, force: true) }
                }
            }
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

    private var listFooter: some View {
        AppUI.listLoadMoreFooter(
            loadingMore: session.isLoadingMoreArticles(tagID: tagID),
            exhausted: session.showsArticlesEndFooter(tagID: tagID)
        )
    }
}
