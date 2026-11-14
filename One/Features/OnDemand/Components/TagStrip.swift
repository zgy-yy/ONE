import SwiftUI

/// 点播顶部分类：底部横线 Tab；未超宽均分，超出宽度仅横向滑动。
struct TagStrip: View {
    let tags: [DemandTag]
    @Binding var selectedTagID: Int?

    var body: some View {
        VStack(spacing: 0) {
            ViewThatFits(in: .horizontal) {
                tagsRow(equalWidth: true)
                ScrollView(.horizontal, showsIndicators: false) {
                    tagsRow(equalWidth: false)
                }
                .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            }
            Divider()
        }
        .padding(.horizontal, 16)
    }

    private func tagsRow(equalWidth: Bool) -> some View {
        HStack(spacing: equalWidth ? 0 : 20) {
            ForEach(tags) { tag in
                tabItem(for: tag, equalWidth: equalWidth)
            }
        }
        .frame(maxWidth: equalWidth ? .infinity : nil, alignment: .leading)
    }

    private func tabItem(for tag: DemandTag, equalWidth: Bool) -> some View {
        let isSelected = selectedTagID == tag.id

        return Button {
            selectedTagID = tag.id
        } label: {
            Text(tag.displayTitle)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, equalWidth ? 4 : 2)
                .padding(.top, 10)
                .padding(.bottom, 8)
                .frame(maxWidth: equalWidth ? .infinity : nil)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(isSelected ? Color.accentColor : .clear)
                        .frame(height: 2)
                }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}