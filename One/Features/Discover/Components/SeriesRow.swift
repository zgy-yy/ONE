import SwiftUI

/// 发现页写真 / 漫画列表行。
struct SeriesRow: View {
    let item: SeriesSummary

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            OneCoverImage(path: item.imagePath)
                .frame(width: 120)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.displayTitle)
                    .font(.body.weight(.medium))
                    .lineLimit(2)

                if let author = item.author?.nonEmpty {
                    Text(author)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    Text(item.statusText)
                        .font(.caption2)
                        .foregroundStyle(item.isFinished ? Color.secondary : Color.accentColor)

                    if let likes = item.likeTotal?.nonEmpty {
                        Text("赞 \(likes)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                if let latest = item.latestAt?.nonEmpty {
                    Text(latest)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}
