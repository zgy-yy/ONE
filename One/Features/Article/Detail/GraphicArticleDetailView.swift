import SwiftUI

/// 图文详情：竖封面 → 标题 / 简介 / 作者 → 页内评论。
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
                    .padding(.bottom, 24)
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

        return VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

            if let description {
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let author {
                Text(author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
