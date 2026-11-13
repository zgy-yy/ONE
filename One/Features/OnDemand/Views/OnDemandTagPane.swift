import SwiftUI

/// 单个点播分类下的文章列表。
struct OnDemandTagPane: View {
    let tag: DemandTag
    @Bindable private var session = OnDemandSession.shared

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
        .refreshable { await session.loadArticles(for: tagID, force: true) }
    }

    private var articleList: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(sections) { section in
                    Section {
                        ForEach(section.articles) { article in
                            articleRow(article)
                                .styledListRow()
                                .onAppear {
                                    guard isListEnd(article, in: section) else { return }
                                    Task { await session.loadMoreArticles(for: tagID) }
                                }
                        }
                    } header: {
                        Text(MonthYear(apiString: section.month)?.displayTitle ?? section.month)
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
                if sections.contains(where: { $0.month == month }) {
                    scrollToMonth(month, proxy: proxy)
                } else {
                    Task { await session.loadArticles(for: tagID, force: true) }
                }
            }
            .onChange(of: sections.map(\.month)) { _, _ in
                scrollToMonth(session.listPublishedAt, proxy: proxy)
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

    @ViewBuilder
    private var listFooter: some View {
        if session.isLoadingMoreArticles(tagID: tagID) {
            ProgressView()
                .listFooterRow()
        } else if session.showsArticlesEndFooter(tagID: tagID) {
            Text("没有更多了")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .listFooterRow()
        }
    }

    private func articleRow(_ article: ArticleSummary) -> some View {
        HStack(alignment: .top, spacing: 12) {
            OneCoverImage(path: article.thumb)
            VStack(alignment: .leading, spacing: 6) {
                Text(article.displayTitle)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                if let author = article.author, !author.isEmpty {
                    Text(author)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let publishedAt = article.publishedAt, !publishedAt.isEmpty {
                    Text(publishedAt)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}
