import SwiftUI

/// 图文详情：竖封面 → 标题居中 / 简介 / 作者与收藏·喜欢 → 评论。
struct GraphicArticleDetailView: View {
    let article: ArticleSummary

    @State private var session = ArticleDetailSession()

    var body: some View {
        ArticleDetailChrome(article: article, session: session) {
            ArticleDetailScrollLayout(
                coverPath: session.detail?.thumb ?? article.thumb,
                placeholderAspect: CoverAspect.portrait
            ) {
                meta
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                ArticleDetailCommentsSection(session: session)
                    .padding(.horizontal, 16)

                ArticlePlayURLFooter(entries: session.playURLEntries)
                    .padding(.horizontal, 16)
            }
            .task(id: article.id) {
                await session.loadComments()
            }
        }
    }

    private var meta: some View {
        let detail = session.detail
        let title = detail?.displayTitle ?? article.displayTitle
        let description = detail?.summary?.nonEmpty ?? article.summary?.nonEmpty
        let author = detail?.author?.nonEmpty ?? article.author?.nonEmpty

        return VStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            if let description {
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            authorAndReactionsRow(
                author: author,
                detail: detail
            )
        }
    }

    @ViewBuilder
    private func authorAndReactionsRow(author: String?, detail: ArticleDetail?) -> some View {
        let collected = detail?.hasCollected ?? article.hasCollected
        let liked = detail?.isLiked ?? article.isLiked
        let collectCount = detail?.collectionNumber ?? article.collectionNumber
        let likeCount = detail?.likeNumber ?? article.likeNumber

        HStack(alignment: .center, spacing: 12) {
            if let author {
                Text(author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Spacer(minLength: 0)
            }

            HStack(spacing: 16) {
                Button {
                    Task { await session.toggleCollect() }
                } label: {
                    ArticleDetailIconLabel(
                        systemImage: collected ? ArticleDetailSymbol.collectOn : ArticleDetailSymbol.collect,
                        text: ArticleFormat.shortCount(collectCount ?? 0),
                        active: collected
                    )
                }
                .buttonStyle(.plain)
                .disabled(session.detail == nil || session.isReacting)

                Button {
                    Task { await session.toggleLike() }
                } label: {
                    ArticleDetailIconLabel(
                        systemImage: liked ? ArticleDetailSymbol.likeOn : ArticleDetailSymbol.like,
                        text: ArticleFormat.shortCount(likeCount ?? 0),
                        active: liked
                    )
                }
                .buttonStyle(.plain)
                .disabled(session.detail == nil || session.isReacting)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("图文详情") {
    NavigationStack {
        GraphicArticleDetailView(article: GraphicArticleDetailPreview.article)
    }
}

private enum GraphicArticleDetailPreview {
    private static let thumb =
        "https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400&h=533&fit=crop"

    static let article = ArticleSummary(
        id: 8401,
        title: "图文详情预览 · 标题居中展示",
        thumb: thumb,
        author: "摄影组",
        publishedAt: "2024-08-15",
        modelID: ContentCategory.ModelID.graphic,
        summary: "简介左对齐；作者与收藏、喜欢同一行。",
        likeNumber: 1280,
        collectionNumber: 456,
        views: 88_000,
        isLike: 1,
        isCollected: 0
    )
}
