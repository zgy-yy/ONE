import SwiftUI

/// 写真 / 漫画系列列表行。
struct SeriesRow: View {
    let item: SeriesSummary
    private let coverWidth: CGFloat = 156

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            OneCoverImage(path: item.imagePath)
                .frame(width: coverWidth)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.displayTitle)
                    .font(ArticleRowTypography.title)
                    .lineLimit(2)

                if let author = item.author?.nonEmpty {
                    Text(author)
                        .font(ArticleRowTypography.summary)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 10) {
                    Text(item.statusText)
                        .font(ArticleRowTypography.metaSmall)
                        .foregroundStyle(item.isFinished ? Color.secondary : Color.accentColor)

                    if let raw = item.likeTotal?.nonEmpty {
                        MetaIconText.likesText(raw)
                            .font(ArticleRowTypography.metaSmall)
                            .foregroundStyle(.tertiary)
                    }
                }

                ArticleDateText(publishedAt: item.latestAt ?? item.firstAt)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
    }
}
