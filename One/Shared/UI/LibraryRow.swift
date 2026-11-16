import SwiftUI

/// 通用库条目行：封面 + 标题（可选作者 / 副标题）。
struct LibraryRow: View {
    let title: String
    var author: String? = nil
    var imagePath: String? = nil
    var subtitle: String? = nil
    var coverAspectRatio: CGFloat = CoverAspect.landscape

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            OneCoverImage(path: imagePath, aspectRatio: coverAspectRatio)
                .frame(width: 120)
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.body.weight(.medium))
                    .lineLimit(2)
                if let author = author?.nonEmpty {
                    Text(author)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let subtitle = subtitle?.nonEmpty {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}
