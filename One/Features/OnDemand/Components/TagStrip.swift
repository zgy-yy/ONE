import SwiftUI

/// 点播顶部分类胶囊条（点击切换）。
struct TagStrip: View {
    let tags: [DemandTag]
    @Binding var selectedTagID: Int?

    private var useFixedLayout: Bool { tags.count <= 5 }

    var body: some View {
        Group {
            if useFixedLayout {
                segmentBar(expands: true)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    segmentBar(expands: false)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func segmentBar(expands: Bool) -> some View {
        GlassEffectContainer(spacing: 4) {
            HStack(spacing: 4) {
                ForEach(tags) { tag in
                    segmentButton(for: tag, expands: expands)
                }
            }
            .padding(6)
        }
        .glassEffect(.regular.interactive(), in: .capsule)
    }

    private func segmentButton(for tag: DemandTag, expands: Bool) -> some View {
        let isSelected = selectedTagID == tag.id

        return Button {
            selectedTagID = tag.id
        } label: {
            Text(tag.displayTitle)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, expands ? 4 : 14)
                .padding(.vertical, 9)
                .frame(maxWidth: expands ? .infinity : nil)
                .background {
                    if isSelected {
                        Capsule(style: .continuous)
                            .fill(.quaternary)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}
