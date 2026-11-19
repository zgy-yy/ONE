import SwiftUI

/// 发现「影视」：左 16:9 封面，右标题 / 收藏·喜欢 / 日期。
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

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 14) {
                        Image(systemName: "bookmark")
                        if let likes = article.likeNumber {
                            MetaIconText.likes(likes)
                        }
                    }
                    if showsDate {
                        ArticleDateText(publishedAt: article.publishedAt)
                    }
                }
                .font(ArticleRowTypography.meta)
                .foregroundStyle(.secondary)
            }
            .matchCoverHeight(width: coverWidth)
        }
        .padding(.vertical, 2)
    }
}
