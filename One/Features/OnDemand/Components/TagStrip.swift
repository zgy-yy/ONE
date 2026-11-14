import SwiftUI

/// 点播分类：横向滑动、完整标题；选中为胶囊高亮，并滚到屏幕中央。
struct TagStrip: View {
    let tags: [DemandTag]
    @Binding var selectedTagID: Int?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tags) { tag in
                        tagChip(for: tag)
                            .id(tag.id)
                            // 不用 Button，避免系统先滚到可见再被居中纠正（会左右晃）。
                            .onTapGesture { selectedTagID = tag.id }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .background(Color(.systemBackground))
            .onAppear {
                if let selectedTagID {
                    proxy.scrollTo(selectedTagID, anchor: .center)
                }
            }
            .onChange(of: selectedTagID) { _, newID in
                guard let newID else { return }
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(newID, anchor: .center)
                }
            }
        }
    }

    private func tagChip(for tag: DemandTag) -> some View {
        let isSelected = selectedTagID == tag.id

        return Text(tag.displayTitle)
            .font(.subheadline.weight(isSelected ? .semibold : .regular))
            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background {
                Capsule()
                    .fill(isSelected ? Color.accentColor.opacity(0.14) : Color.clear)
            }
            .contentShape(Capsule())
            .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}
