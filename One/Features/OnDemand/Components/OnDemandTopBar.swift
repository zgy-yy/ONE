import SwiftUI

/// 点播页顶栏：筛选 + 分类胶囊。
struct OnDemandTopBar: View {
    let tags: [DemandTag]
    @Binding var selectedTagID: Int?
    @Bindable var session: OnDemandSession

    var body: some View {
        VStack(spacing: 0) {
            OnDemandFilterBar(session: session)
            TagStrip(tags: tags, selectedTagID: $selectedTagID)
        }
    }
}
