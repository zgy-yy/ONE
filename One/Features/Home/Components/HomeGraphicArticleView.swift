import SwiftUI

/// 首页「图文」条目：原图封面，其下标题 → 简介 → 作者。
struct HomeGraphicArticleView: View {
    let article: ArticleSummary
    var textAlignment: TextAlignment = .center
    var showsDescription: Bool = true
    var cornerRadius: CGFloat = 8

    private var stackAlignment: HorizontalAlignment {
        textAlignment == .center ? .center : .leading
    }

    private var frameAlignment: Alignment {
        textAlignment == .center ? .center : .leading
    }

    var body: some View {
        VStack(alignment: stackAlignment, spacing: 6) {
            cover
            line(article.displayTitle, font: ArticleRowTypography.cardTitle, color: .primary, lines: 2)
            if showsDescription, let summary = article.summary?.nonEmpty {
                line(summary, font: ArticleRowTypography.summary, color: .secondary, lines: 2)
            }
            if let author = article.author?.nonEmpty {
                line(author, font: ArticleRowTypography.metaSmall, color: .secondary, lines: 1)
            }
        }
    }

    private var cover: some View {
        OneCoverImage(
            path: article.thumb,
            usesOriginalAspectRatio: true,
            placeholderAspectRatio: CoverAspect.portrait,
            cornerRadius: 0
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private func line(_ text: String, font: Font, color: Color, lines: Int) -> some View {
        Text(text)
            .font(font)
            .foregroundStyle(color)
            .lineLimit(lines)
            .multilineTextAlignment(textAlignment)
            .frame(maxWidth: .infinity, alignment: frameAlignment)
    }
}