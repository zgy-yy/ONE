import SwiftUI

/// 单个分类下的文章列表页（由横向 `TabView` 承载，每个分类一页）。
///
/// - `.task(id: tag.id)`：分类变化时重新拉列表。
/// - `.refreshable`：下拉刷新当前分类。
/// - `List` + `Identifiable`：`ArticleSummary` 提供 `id` 即可 `ForEach`/`List` 直接遍历。
struct TabTagPane: View {
    let tag: DemandTag
    @Bindable private var session = TabSession.shared

    private var articles: [ArticleSummary] {
        session.articles(for: tag.id)
    }

    var body: some View {
        Group {
            if session.isLoadingArticles(tagID: tag.id), articles.isEmpty {
                ProgressView("加载列表…")
                    .tint(.white)
            } else if let error = session.articleError(for: tag.id), articles.isEmpty {
                ContentUnavailableView {
                    Label("加载失败", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(error)
                } actions: {
                    Button("重试") {
                        Task { await session.loadArticles(for: tag.id, force: true) }
                    }
                }
            } else if articles.isEmpty {
                emptyPlaceholder
            } else {
                articleList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .task(id: tag.id) {
            await session.loadArticles(for: tag.id)
        }
        .refreshable {
            await session.loadArticles(for: tag.id, force: true)
        }
    }

    private var emptyPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "circle.slash")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Color(white: 0.35))
            Text("无内容")
                .font(.title3)
                .foregroundStyle(Color(white: 0.35))
        }
    }

    private var articleList: some View {
        List(articles) { article in
            HStack(alignment: .top, spacing: 12) {
                OneCoverImage(path: article.thumb)
                VStack(alignment: .leading, spacing: 6) {
                    Text(article.title?.isEmpty == false ? article.title! : "ID \(article.id)")
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
            .listRowBackground(Color(white: 0.08))
            .listRowSeparatorTint(Color(white: 0.15))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}
