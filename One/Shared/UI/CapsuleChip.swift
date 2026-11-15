import SwiftUI

/// 横向筛选 / Tab 通用胶囊。
struct CapsuleChip: View {
    let title: String
    var selected: Bool
    var compact: Bool = false

    var body: some View {
        Text(title)
            .font(compact
                ? .caption.weight(selected ? .semibold : .regular)
                : .subheadline.weight(selected ? .semibold : .regular))
            .foregroundStyle(selected ? Color.accentColor : Color.secondary)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, compact ? 12 : 14)
            .padding(.vertical, compact ? 6 : 7)
            .background {
                Capsule().fill(
                    selected
                        ? Color.accentColor.opacity(0.14)
                        : (compact ? Color(.secondarySystemFill) : Color.clear)
                )
            }
            .contentShape(Capsule())
            .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
    }
}

/// 横向胶囊条：选中项自动滚到中央。
struct HorizontalCapsuleStrip<Item: Identifiable, ID: Hashable>: View {
    let items: [Item]
    let selectedID: ID?
    let title: (Item) -> String
    let id: (Item) -> ID
    let onSelect: (Item) -> Void
    var compact: Bool = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(items) { item in
                        let itemID = id(item)
                        CapsuleChip(
                            title: title(item),
                            selected: selectedID == itemID,
                            compact: compact
                        )
                        .id(itemID)
                        .onTapGesture { onSelect(item) }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, compact ? 8 : 10)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .onAppear {
                if let selectedID {
                    proxy.scrollTo(selectedID, anchor: .center)
                }
            }
            .onChange(of: selectedID) { _, newID in
                guard let newID else { return }
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(newID, anchor: .center)
                }
            }
        }
    }
}
