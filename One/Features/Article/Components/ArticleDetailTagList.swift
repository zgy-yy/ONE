import SwiftUI

/// 精彩预览下方的 `tag_list`。
struct ArticleDetailTagList: View {
    let tags: [ArticleDetailTag]

    private let columns = [GridItem(.adaptive(minimum: 44), spacing: 6, alignment: .leading)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
            ForEach(tags) { tag in
                TagChip(title: tag.displayName)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TagChip: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption2)
            .foregroundStyle(.primary)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}