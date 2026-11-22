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

/// 等分胶囊分段：选中项背景滑动（创建时间 / 收藏时间等）。
struct SlidingCapsuleSegmented<Item: Hashable>: View {
    let items: [Item]
    let title: (Item) -> String
    @Binding var selection: Item

    @Namespace private var segmentPill

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items, id: \.self) { item in
                let isSelected = selection == item
                Button {
                    guard selection != item else { return }
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                        selection = item
                    }
                } label: {
                    Text(title(item))
                        .font(.caption.weight(isSelected ? .semibold : .medium))
                        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.07), radius: 2, y: 1)
                                    .matchedGeometryEffect(id: "segmentPill", in: segmentPill)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
            }
        }
        .padding(4)
        .background(Capsule().fill(Color(.tertiarySystemFill)))
    }
}
