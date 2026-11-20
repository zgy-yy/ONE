import SwiftUI

/// 发现「阅读」：左方封面，右标题 / 作者·日期 / 喜欢。
struct ReadingArticleRow: View {
    let article: ArticleSummary
    var showsDate: Bool = true
    private let coverWidth: CGFloat = 96

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            OneCoverImage(
                path: article.thumb,
                aspectRatio: CoverAspect.square,
                cornerRadius: 8
            )
            .frame(width: coverWidth)

            VStack(alignment: .leading, spacing: 6) {
                Text(article.displayTitle)
                    .font(ArticleRowTypography.filmTitle)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                HStack(spacing: 8) {
                    if let author = article.author?.nonEmpty {
                        Text(author)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    if showsDate {
                        ArticleDateText(publishedAt: article.publishedAt)
                    }
                }
                .font(ArticleRowTypography.summary)

                Spacer(minLength: 0)

                ArticleCollectLikeMeta(article: article)
                    .font(ArticleRowTypography.meta)
            }
            .matchCoverHeight(width: coverWidth, aspect: CoverAspect.square)
        }
        .padding(.vertical, 2)
    }
}