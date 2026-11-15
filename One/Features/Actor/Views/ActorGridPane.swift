import SwiftUI

/// 演员三列网格（最新 / 最热 / 分类共用）。
struct ActorGridPane: View {
    let selection: ActorTabSelection
    var tags: [ActorNavTag] = []

    @Bindable private var session = ActorSession.shared

    private var actors: [ActorSummary] { session.actors(for: selection) }
    private var loadToken: String { session.feedFetchKey(for: selection) }
    private var navigationID: Int? {
        if case .navigation(let id) = selection { return id }
        return nil
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        AsyncPage(
            isLoading: session.isLoadingActors(selection),
            error: session.error(for: selection),
            isEmpty: actors.isEmpty,
            loadingTitle: "加载演员…",
            emptyIcon: "person.slash",
            emptyTitle: "暂无演员",
            retry: { Task { await session.loadActors(selection: selection, force: true) } }
        ) {
            actorGrid
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if let navigationID, !tags.isEmpty {
                VStack(spacing: 0) {
                    ActorTagFilterStrip(tags: tags, navigationID: navigationID, session: session)
                    Divider()
                }
                .background(Color(.systemBackground))
            }
        }
        .task(id: loadToken) {
            await session.loadActors(selection: selection)
        }
    }

    private var actorGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(actors) { actor in
                    NavigationLink(value: actor) { actorCell(actor) }
                        .buttonStyle(.plain)
                        .onAppear {
                            guard actors.isLastItem(actor) else { return }
                            Task { await session.loadMoreActors(selection: selection) }
                        }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            AppUI.loadMoreFooter(
                loadingMore: session.isLoadingMoreActors(selection),
                exhausted: session.showsEndFooter(selection)
            )
            .padding(.bottom, 16)
        }
        .tracksSearchFABScroll()
    }

    private func actorCell(_ actor: ActorSummary) -> some View {
        VStack(spacing: 6) {
            ActorAvatarImage(path: actor.imagePath)
            Text(actor.displayName)
                .font(.caption)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
            meta(for: actor)
        }
    }

    @ViewBuilder
    private func meta(for actor: ActorSummary) -> some View {
        switch selection {
        case .hottest:
            if let score = actor.score {
                Text("热度 \(score)").font(.caption2).foregroundStyle(.tertiary).lineLimit(1)
            }
        case .newest:
            if let date = actor.latestPublishedAt?.nonEmpty {
                Text(date).font(.caption2).foregroundStyle(.tertiary).lineLimit(1)
            }
        case .navigation:
            EmptyView()
        }
    }
}
