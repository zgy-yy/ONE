import SwiftUI

/// 点播页顶栏：筛选 + 分类胶囊。
struct TopBar: View {
    let tags: [DemandTag]
    @Binding var selectedTagID: Int?
    @Bindable var session: VodSession

    var body: some View {
        VStack(spacing: 0) {
            FilterBar(publishedAt: $session.listPublishedAt, sort: $session.listSort)
            TagStrip(tags: tags, selectedTagID: $selectedTagID)
        }
        .background(Color(.systemBackground))
    }
}
