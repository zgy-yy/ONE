import SwiftUI

/// 点播分类：横向滑动、完整标题；选中为胶囊高亮。
struct TagStrip: View {
    let tags: [DemandTag]
    @Binding var selectedTagID: Int?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags) { tag in
                    tabItem(for: tag)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .background(Color(.systemBackground))
    }

    private func tabItem(for tag: DemandTag) -> some View {
        let isSelected = selectedTagID == tag.id

        return Button {
            selectedTagID = tag.id
        } label: {
            Text(tag.displayTitle)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background {
                    Capsule()
                        .fill(isSelected ? Color.accentColor.opacity(0.14) : Color.clear)
                }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}