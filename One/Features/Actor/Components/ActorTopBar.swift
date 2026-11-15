import SwiftUI

/// 顶栏：最新 / 最热 + 主分类；选中项滚到可见区中央。
struct ActorTopBar: View {
    let navigations: [ActorNavigation]
    @Binding var selection: ActorTabSelection

    private var items: [ActorTabItem] {
        var result: [ActorTabItem] = [
            .init(id: .newest, title: "最新"),
            .init(id: .hottest, title: "最热"),
        ]
        result += navigations.map {
            .init(id: .navigation($0.id), title: $0.displayName)
        }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            HorizontalCapsuleStrip(
                items: items,
                selectedID: selection,
                title: \.title,
                id: \.id,
                onSelect: { selection = $0.id }
            )
            Divider()
        }
        .background(Color(.systemBackground))
    }
}

private struct ActorTabItem: Identifiable {
    let id: ActorTabSelection
    let title: String
}
