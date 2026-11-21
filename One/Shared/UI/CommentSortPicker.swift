import SwiftUI

/// 评论排序：最新 / 最热（胶囊切换）。
struct CommentSortPicker: View {
    @Binding var sort: CommentSort
    /// 评论区顶栏略大；楼中楼略小。
    var style: Style = .section

    enum Style {
        case section
        case replyThread
    }

    private var compact: Bool { style == .replyThread }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(CommentSort.allCases) { item in
                Button {
                    sort = item
                } label: {
                    Text(item.title)
                        .font(compact ? .caption2.weight(.medium) : .caption.weight(.medium))
                        .foregroundStyle(sort == item ? Color.primary : Color.secondary)
                        .frame(minWidth: compact ? 36 : 44)
                        .padding(.horizontal, compact ? 8 : 10)
                        .padding(.vertical, compact ? 4 : 5)
                        .background {
                            if sort == item {
                                Capsule().fill(Color(.secondarySystemBackground))
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(Color(.tertiarySystemFill), in: Capsule())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("评论排序")
    }
}