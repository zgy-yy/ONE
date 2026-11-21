import SwiftUI

/// 发现「阅读」：左方封面，右标题（一行）/ 简介 / 作者；底栏收藏·喜欢与日期分居两侧。
struct ReadingArticleRow: View {
    let article: ArticleSummary
    private let coverWidth: CGFloat = 106

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            OneCoverImage(
                path: article.thumb,
                aspectRatio: CoverAspect.square,
                cornerRadius: 8
            )
            .frame(width: coverWidth)

            textColumn
                .matchCoverHeight(width: coverWidth, aspect: CoverAspect.square, padding:1)
        }
        .padding(.vertical, 2)
    }

    private var textColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(article.displayTitle)
                .font(ArticleRowTypography.filmTitle)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            blurbBlock
                .padding(.top, 3)
            Spacer(minLength: 0)
            metaBar
        }
    }

    @ViewBuilder
    private var blurbBlock: some View {
        let hasSummary = article.summary?.nonEmpty != nil
        let hasAuthor = article.author?.nonEmpty != nil

        if hasSummary || hasAuthor {
            VStack(alignment: .leading, spacing: hasSummary && hasAuthor ? 8 : 0) {
                if let summary = article.summary?.nonEmpty {
                    Text(summary)
                        .font(ArticleRowTypography.summary)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .lineSpacing(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let author = article.author?.nonEmpty {
                    Text("文 / \(author)")
                        .font(ArticleRowTypography.metaSmall)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
        }
    }

    private var metaBar: some View {
        HStack(alignment: .center, spacing: 8) {
                ArticleCollectLikeMeta(article: article)
            Spacer(minLength: 0)
            ArticleDateText(
                publishedAt: article.publishedAt,
                font: ArticleRowTypography.metaSmall
            )
        }
        .font(ArticleRowTypography.metaSmall)
    }
}