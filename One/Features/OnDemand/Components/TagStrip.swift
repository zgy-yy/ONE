import SwiftUI

/// 点播分类横向胶囊；选中滚到中央。
struct TagStrip: View {
    let tags: [DemandTag]
    @Binding var selectedTagID: Int?

    var body: some View {
        HorizontalCapsuleStrip(
            items: tags,
            selectedID: selectedTagID,
            title: \.displayTitle,
            id: \.id,
            onSelect: { selectedTagID = $0.id }
        )
        .background(Color(.systemBackground))
    }
}
