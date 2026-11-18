import SwiftUI

/// 发现页写真 / 漫画列表行。
struct SeriesRow: View {
    let item: SeriesSummary

    private let coverWidth: CGFloat = SeriesUI.coverWidth

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            OneCoverImage(path: item.imagePath)
                .frame(width: coverWidth)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.displayTitle)
                    .font(.body.weight(.medium))
                    .lineLimit(2)

                if let author = item.author?.nonEmpty {
                    Text(author)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                HStack(spacing: 10) {
                    Text(item.statusText)
                        .font(.caption2)
                        .foregroundStyle(item.isFinished ? Color.secondary : Color.accentColor)

                    if let likes = item.likeTotal?.nonEmpty {
                        MetaIconText(systemImage: "heart", text: likes)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .matchCoverHeight(width: coverWidth)
        }
        .padding(.vertical, 4)
    }
}

enum SeriesUI {
    /// 写真 / 漫画列表与章节行共用封面宽度。
    static let coverWidth: CGFloat = 186
}
