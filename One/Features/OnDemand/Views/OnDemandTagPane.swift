import SwiftUI

/// 单个点播分类下的文章列表（横向 `TabView` 一页）。
struct OnDemandTagPane: View {
    let tag: DemandTag
    @Bindable private var session = OnDemandSession.shared

    private var tagID: Int { tag.id }
    private var articles: [ArticleSummary] { session.articles(for: tagID) }

    var body: some View {
        Group {
            if session.isLoadingArticles(tagID: tagID), articles.isEmpty {
                OnDemandUI.loading("加载列表…")
            } else if let error = session.articleError(for: tagID), articles.isEmpty {
                OnDemandUI.loadFailure(message: error) {
                    Task { await session.loadArticles(for: tagID, force: true) }
                }
            } else if articles.isEmpty {
                OnDemandUI.emptyState(icon: "circle.slash", title: "无内容")
            } else {
                articleList
            }
        }
        .onDemandPage()
        .task(id: tagID) { await session.loadArticles(for: tagID) }
        .refreshable { await session.loadArticles(for: tagID, force: true) }
    }

    private var articleList: some View {
        List {
            ForEach(articles) { article in
                articleRow(article)
                    .listRowBackground(OnDemandUI.listRowBackground)
                    .listRowSeparatorTint(OnDemandUI.listRowSeparator)
                    .onAppear {
                        guard article.id == articles.last?.id, session.hasMoreArticles(tagID: tagID) else { return }
                        Task { await session.loadMoreArticles(for: tagID) }
                    }
            }
            listFooter
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private var listFooter: some View {
        if session.isLoadingMoreArticles(tagID: tagID) {
            ProgressView()
                .tint(.white)
                .onDemandListFooterRow()
        } else if session.showsArticlesEndFooter(tagID: tagID) {
            Text("没有更多了")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .onDemandListFooterRow()
        }
    }

    private func articleRow(_ article: ArticleSummary) -> some View {
        HStack(alignment: .top, spacing: 12) {
            OneCoverImage(path: article.thumb)
            VStack(alignment: .leading, spacing: 6) {
                Text(article.displayTitle)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)
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
