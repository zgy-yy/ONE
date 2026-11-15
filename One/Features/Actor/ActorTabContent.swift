import SwiftUI

/// 「演员」Tab：最新 / 最热 / 主分类。
struct ActorTabContent: View {
    @Bindable private var session = ActorSession.shared
    @State private var selection: ActorTabSelection = .newest

    var body: some View {
        NavigationStack {
            content
                .fillPage()
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: ActorSummary.self) { ActorDetailView(actor: $0) }
                .task { await session.loadIfNeeded() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if session.isLoading, session.navigations.isEmpty {
            AppUI.loading("加载演员分类…")
        } else if let lastError = session.lastError, session.navigations.isEmpty {
            AppUI.loadFailure(message: lastError) {
                Task { await session.refresh(force: true) }
            }
        } else {
            ActorGridPane(
                selection: selection,
                tags: currentTags
            )
            .id(selection)
            .safeAreaInset(edge: .top, spacing: 0) {
                ActorTopBar(navigations: session.navigations, selection: $selection)
            }
        }
    }

    private var currentTags: [ActorNavTag] {
        guard case .navigation(let id) = selection,
              let nav = session.navigations.first(where: { $0.id == id })
        else { return [] }
        return nav.displayTags
    }
}

#Preview {
    ActorTabContent()
}
