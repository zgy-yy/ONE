import SwiftUI

/// 发现「影视」：左 16:9 封面，右标题 / 作者 / 收藏·喜欢 / 日期。
struct FilmArticleRow: View {
    let article: ArticleSummary
    var showsDate: Bool = true
    private let coverWidth: CGFloat = 186

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            OneCoverImage(
                path: article.thumb,
                aspectRatio: CoverAspect.landscape,
                cornerRadius: 8
            )
            .frame(width: coverWidth)

            VStack(alignment: .leading, spacing: 6) {
                Text(article.displayTitle)
                    .font(ArticleRowTypography.title)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    // 与 Spacer 抢高度时优先保两行，避免被压成一行。
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                if let author = article.author?.nonEmpty {
                    Text(author)
                        .font(ArticleRowTypography.summary)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 6) {
                    ArticleCollectLikeMeta(article: article)
                    if showsDate {
                        ArticleDateText(publishedAt: article.publishedAt)
                    }
                }
                .font(ArticleRowTypography.meta)
            }
            .matchCoverHeight(width: coverWidth)
        }
        .padding(.vertical, 2)
    }
}
