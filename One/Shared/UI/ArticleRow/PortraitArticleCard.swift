import SwiftUI

/// 竖图卡片：封面 + 标题 / 简介 / 作者 / 日期。
/// 首页图文、月网格（居中）；发现图文两列（可左对齐）。
struct PortraitArticleCard: View {
    let article: ArticleSummary
    var textAlignment: TextAlignment = .center
    var cornerRadius: CGFloat = 8
    var showsDate: Bool = true
    var showsDescription: Bool = false
    /// 默认竖图网格；首页图文与 `FilmArticleRow` 对齐。
    var titleFont: Font = ArticleRowTypography.cardTitle
    var collectLikeFont: Font = ArticleRowTypography.metaSmall

    private var stackAlignment: HorizontalAlignment {
        textAlignment == .center ? .center : .leading
    }

    private var frameAlignment: Alignment {
        textAlignment == .center ? .center : .leading
    }

    var body: some View {
        VStack(alignment: stackAlignment, spacing: 6) {
            OneCoverImage(
                path: article.thumb,
                aspectRatio: CoverAspect.portrait,
                cornerRadius: cornerRadius
            )
            line(article.displayTitle, font: titleFont, color: .primary, limit: 2)
            if showsDescription, let summary = article.summary?.nonEmpty {
                line(summary, font: ArticleRowTypography.metaSmall, color: .secondary, limit: 2)
            }
            if let author = article.author?.nonEmpty {
                line(author, font: ArticleRowTypography.metaSmall, color: .secondary, limit: 1)
            }
            ArticleCollectLikeMeta(article: article)
                .font(collectLikeFont)
                .frame(maxWidth: .infinity, alignment: frameAlignment)
            if showsDate {
                ArticleDateText(publishedAt: article.publishedAt, font: ArticleRowTypography.metaSmall)
                    .frame(maxWidth: .infinity, alignment: frameAlignment)
            }
        }
    }

    private func line(
        _ text: String,
        font: Font,
        color: Color,
        limit: Int
    ) -> some View {
        Text(text)
            .font(font)
            .foregroundStyle(color)
            .lineLimit(limit)
            .multilineTextAlignment(textAlignment)
            .frame(maxWidth: .infinity, alignment: frameAlignment)
    }
}
