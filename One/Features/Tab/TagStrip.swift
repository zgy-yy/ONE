import SwiftUI

/// 顶部胶囊分段；使用与系统 Tab 相同的 Liquid Glass（需自定义视图显式加 `glassEffect`）
struct TagStrip: View {
    let tags: [DemandTag]
    @Binding var selectedTagID: Int?

    @Namespace private var selectionNS

    var body: some View {
        Group {
            if tags.count <= 5 {
                fixedSegmentBar
            } else {
                scrollableSegmentBar
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private var fixedSegmentBar: some View {
        GlassEffectContainer(spacing: 4) {
            HStack(spacing: 4) {
                ForEach(tags) { tag in
                    segmentButton(for: tag, expands: true)
                }
            }
            .padding(4)
        }
        .glassEffect(.regular, in: .capsule)
    }

    private var scrollableSegmentBar: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                GlassEffectContainer(spacing: 4) {
                    HStack(spacing: 4) {
                        ForEach(tags) { tag in
                            segmentButton(for: tag, expands: false)
                                .id(tag.id)
                        }
                    }
                    .padding(4)
                }
            }
            .glassEffect(.regular, in: .capsule)
            .onChange(of: selectedTagID) { _, newID in
                guard let newID else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(newID, anchor: .center)
                }
            }
        }
    }

    private func segmentButton(for tag: DemandTag, expands: Bool) -> some View {
        let title = tag.title?.isEmpty == false ? tag.title! : "标签 \(tag.id)"
        let isSelected = selectedTagID == tag.id

        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                selectedTagID = tag.id
            }
        } label: {
            Text(title)
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
                            .matchedGeometryEffect(id: "tagThumb", in: selectionNS)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}
