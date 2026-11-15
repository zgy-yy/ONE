import SwiftUI

/// 分类标签多选（→ `tag_ids`）。
struct ActorTagFilterStrip: View {
    let tags: [ActorNavTag]
    let navigationID: Int
    @Bindable var session: ActorSession

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags) { tag in
                    CapsuleChip(
                        title: tag.displayName,
                        selected: session.isTagSelected(navigationID: navigationID, tagID: tag.id),
                        compact: true
                    )
                    .onTapGesture {
                        session.toggleTag(navigationID: navigationID, tagID: tag.id)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
    }
}
