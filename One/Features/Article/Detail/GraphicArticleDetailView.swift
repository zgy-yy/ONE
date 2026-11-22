import SwiftUI

/// 图文详情：竖封面 → 标题居中 / 简介 / 作者与收藏·喜欢 → 评论。
struct GraphicArticleDetailView: View {
    let article: ArticleSummary

    @State private var session = ArticleDetailSession()
    @State private var collectMoveContext: CollectFolderMoveContext?

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
        .articleCollectMoveFlow($collectMoveContext) {
            session.syncReactionsFromStore()
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

            ArticleDetailEngagementRow(
                article: article,
                detail: detail,
                interactionDisabled: detail == nil,
                onCollect: {
                    Task {
                        collectMoveContext = await ArticleCollectAction.handleInDetail(
                            article: article,
                            syncDetail: { session.syncReactionsFromStore() }
                        )
                    }
                },
                onLike: { Task { await session.toggleLike() } }
            )
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("图文详情") {
    NavigationStack {
        GraphicArticleDetailView(article: PreviewSamples.Article.graphicDetailPage)
    }
}
