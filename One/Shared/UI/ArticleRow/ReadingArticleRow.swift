import SwiftUI

/// 发现「阅读」：左方封面，右标题 / 简介 / 作者 / 喜欢 / 日期。
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

            VStack(alignment: .leading, spacing: 8) {
                Text(article.displayTitle)
                    .font(.body.weight(.semibold))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let summary = article.summary?.nonEmpty {
                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    if let author = article.author?.nonEmpty {
                        Text(author).lineLimit(1)
                    }
                    if let likes = article.likeNumber {
                        MetaIconText.likes(likes)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                if showsDate {
                    ArticleDateText(publishedAt: article.publishedAt)
                }
            }
            .matchCoverHeight(width: coverWidth, aspect: CoverAspect.square)
        }
        .padding(.vertical, 2)
    }
}
