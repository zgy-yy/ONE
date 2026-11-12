import SwiftUI

/// 顶部分类胶囊条（分段控件样式）。
///
/// - `@Binding`：选中项由父视图 `Tab` 持有，子组件读写同一份状态。
/// - `@Namespace` + `matchedGeometryEffect`：选中高亮块滑动时的连贯动画。
/// - `glassEffect`：iOS 26+ 液态玻璃材质（自定义 View 需手动添加，底部系统 Tab 会自动有）。
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
