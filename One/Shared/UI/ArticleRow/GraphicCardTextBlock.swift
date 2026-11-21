import SwiftUI

/// 图文竖卡：标题 / 作者 / 简介（首页与发现共用）。
struct GraphicCardTextBlock: View {
    let title: String
    var author: String?
    var summary: String?
    var showsSummary = true
    var titleAlignment: TextAlignment = .center
    var summaryAlignment: TextAlignment = .leading
    var summaryLineLimit: Int? = nil

    private var stackAlignment: HorizontalAlignment {
        titleAlignment == .center ? .center : .leading
    }

    var body: some View {
        VStack(alignment: stackAlignment, spacing: 6) {
            graphicCardLine(
                title,
                font: ArticleRowTypography.GraphicCard.title,
                color: .primary,
                lines: 2,
                alignment: titleAlignment
            )
            if let author, !author.isEmpty {
                graphicCardLine(
                    author,
                    font: ArticleRowTypography.GraphicCard.author,
                    color: .secondary,
                    lines: 1,
                    alignment: titleAlignment
                )
            }
            if showsSummary, let summary, !summary.isEmpty {
                graphicCardLine(
                    summary,
                    font: ArticleRowTypography.GraphicCard.summary,
                    color: .secondary,
                    lines: summaryLineLimit,
                    alignment: summaryAlignment
                )
            }
        }
    }
}

private func graphicCardLine(
    _ text: String,
    font: Font,
    color: Color,
    lines: Int?,
    alignment: TextAlignment
) -> some View {
    Text(text)
        .font(font)
        .foregroundStyle(color)
        .lineLimit(lines)
        .multilineTextAlignment(alignment)
        .frame(
            maxWidth: .infinity,
            alignment: alignment == .leading ? .leading : (alignment == .trailing ? .trailing : .center)
        )
}