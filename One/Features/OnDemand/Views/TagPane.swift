import SwiftUI

/// 单个点播分类下的文章列表。
struct TagPane: View {
    let tag: DemandTag
    @Bindable private var session = VodSession.shared

    private var tagID: Int { tag.id }
    private var sections: [ArticleMonthSection] { session.articleSections(for: tagID) }

    private var listLoadToken: String {
        "\(tagID)-\(session.articleFetchKey)"
    }

    private var hasNoArticles: Bool {
        sections.isEmpty || sections.allSatisfy(\.articles.isEmpty)
    }

    var body: some View {
        Group {
            if session.isLoadingArticles(tagID: tagID), sections.isEmpty {
                AppUI.loading("加载列表…")
            } else if let error = session.articleError(for: tagID), sections.isEmpty {
                AppUI.loadFailure(message: error) {
                    Task { await session.loadArticles(for: tagID, force: true) }
                }
            } else if hasNoArticles {
                AppUI.emptyState(icon: "circle.slash", title: "无内容")
            } else {
                articleList
            }
        }
        .fillPage()
        .task(id: listLoadToken) { await session.loadArticles(for: tagID) }
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
                                    guard isListEnd(article, in: section) else { return }
                                    Task { await session.loadMoreArticles(for: tagID) }
                                }
                        }
                    } header: {
                        Text(MonthYear.sectionTitle(forAPIString: section.month))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(nil)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                            .id(section.month)
                    }
                }
                listFooter
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
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

    private func isListEnd(_ article: ArticleSummary, in section: ArticleMonthSection) -> Bool {
        guard let tail = sections.last, tail.month == section.month else { return false }
        return tail.articles.last?.id == article.id
    }

    private var listFooter: some View {
        AppUI.listLoadMoreFooter(
            loadingMore: session.isLoadingMoreArticles(tagID: tagID),
            exhausted: session.showsArticlesEndFooter(tagID: tagID)
        )
    }

    private func articleRow(_ article: ArticleSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            OneCoverImage(path: article.thumb)
            article.rowMeta
        }
        .padding(.vertical, 4)
    }
}
