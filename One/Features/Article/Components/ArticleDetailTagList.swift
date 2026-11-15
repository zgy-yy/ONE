import SwiftUI

/// 精彩预览下方的 `tag_list`：按文字自适应宽度，自动换行。
struct ArticleDetailTagList: View {
    let tags: [ArticleDetailTag]

    var body: some View {
        FlowLayout(spacing: 8, lineSpacing: 8) {
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
            .font(.subheadline)
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
    }
}
