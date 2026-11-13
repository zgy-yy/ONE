import SwiftUI

/// 点播顶部分类胶囊条（液态玻璃风格，与系统底部 `TabView` Tab 栏一致）。
struct TagStrip: View {
    let tags: [DemandTag]
    @Binding var selectedTagID: Int?

    @Namespace private var glassNamespace

    private var useFixedLayout: Bool { tags.count <= 5 }

    var body: some View {
        Group {
            if useFixedLayout {
                segmentBar(expands: true)
            } else {
                scrollableSegmentBar
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
                        .id(tag.id)
                        .glassEffectID(tag.id, in: glassNamespace)
                }
            }
            .padding(6)
        }
        .glassEffect(.regular.interactive(), in: .capsule)
    }

    private var scrollableSegmentBar: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                segmentBar(expands: false)
            }
            .onChange(of: selectedTagID) { _, newID in
                guard let newID else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(newID, anchor: .center)
                }
            }
        }
    }

    private func segmentButton(for tag: DemandTag, expands: Bool) -> some View {
        let isSelected = selectedTagID == tag.id

        return Button {
            withAnimation(.snappy(duration: 0.28)) {
                selectedTagID = tag.id
            }
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
                            .glassEffect(.regular.interactive(), in: .capsule)
                            .glassEffectID(tag.id, in: glassNamespace)
                            .glassEffectTransition(.matchedGeometry)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
