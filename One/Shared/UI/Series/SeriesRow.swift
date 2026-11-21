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
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let author = item.author?.nonEmpty {
                    Text("图 / \(author)")
                        .font(ArticleRowTypography.summary)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 10) {
                    Text(item.statusText)
                        .foregroundStyle(item.isFinished ? Color.secondary : Color.accentColor)

                    if let raw = item.likeTotal?.nonEmpty {
                        MetaIconText.likesText(raw)
                    }

                    Spacer(minLength: 0)

                    ArticleDateText(
                        publishedAt: item.latestAt ?? item.firstAt,
                        font: ArticleRowTypography.metaSmall
                    )
                }
                .font(ArticleRowTypography.metaSmall)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .matchCoverHeight(width: coverWidth)
        }
        .padding(.vertical, 2)
    }
}

#Preview("系列行") {
    List {
        SeriesRow(item: SeriesRowPreview.ongoing)
            .styledListRow()
        SeriesRow(item: SeriesRowPreview.finished)
            .styledListRow()
    }
    .plainContentList()
}

private enum SeriesRowPreview {
    private static let coverA =
        "https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400&h=600&fit=crop"
    private static let coverB =
        "https://images.unsplash.com/photo-1529139578806-5813dffbe961?w=400&h=600&fit=crop"

    static let ongoing = SeriesSummary(
        id: 8001,
        title: "海边写真集 · 夏日特辑",
        author: "小林",
        thumb: coverA,
        end: 0,
        firstAt: "2023-06-01 10:00:00",
        latestAt: "2024-08-12 18:30:00",
        likeTotal: "12800"
    )

    static let finished = SeriesSummary(
        id: 8002,
        title: "单行标题也占两行",
        author: "摄影部",
        thumb: coverB,
        end: 1,
        firstAt: "2022-01-15",
        latestAt: "2024-01-20",
        likeTotal: "256"
    )
}
