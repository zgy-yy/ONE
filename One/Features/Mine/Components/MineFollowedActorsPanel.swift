import SwiftUI

/// 「关注」：我收藏的演员（`actor/getCollectActors`）。
struct MineFollowedActorsPanel: View {
    @Bindable private var session = MineLibrarySession.shared

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        AsyncPage(
            isLoading: session.followedActors.isLoading,
            error: session.followedActors.error,
            isEmpty: session.followedActors.isEmpty,
            loadingTitle: "加载关注…",
            emptyIcon: "person.slash",
            emptyTitle: "暂无关注演员",
            retry: { Task { await session.loadFollowedActors(force: true) } }
        ) {
            actorGrid
        }
        .task { await session.loadFollowedActors() }
    }

    private var actorGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(session.followedActors.items) { actor in
                    NavigationLink(value: actor) {
                        actorCell(actor)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        guard session.followedActors.items.isLastItem(actor) else { return }
                        Task { await session.loadMoreFollowedActors() }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            AppUI.listLoadMoreFooter(
                loadingMore: session.followedActors.isLoadingMore,
                exhausted: session.followedActors.exhausted
            )
            .padding(.bottom, 8)
        }
        .refreshable { await session.loadFollowedActors(force: true) }
    }

    private func actorCell(_ actor: ActorSummary) -> some View {
        VStack(spacing: 6) {
            ActorAvatarImage(path: actor.imagePath)
            Text(actor.displayName)
                .font(.caption)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
        }
    }
}