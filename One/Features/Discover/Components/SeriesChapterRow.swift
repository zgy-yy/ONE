import SwiftUI

/// 系列详情章节行。
struct SeriesChapterRow: View {
    let chapter: SeriesChapter

    private let coverWidth: CGFloat = SeriesUI.coverWidth

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            OneCoverImage(path: chapter.imagePath)
                .frame(width: coverWidth)

            VStack(alignment: .leading, spacing: 4) {
                Text(chapter.displayTitle)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)

                if let published = chapter.publishedAt?.nonEmpty {
                    Text(published)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}
