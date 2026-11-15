import SwiftUI

/// 收藏夹 + 收藏内容列表。
struct MyFavoritesView: View {
    @Bindable private var session = MineLibrarySession.shared

    private var loadToken: String {
        "\(session.selectedFolderID)-\(session.favoriteCategory.rawValue)"
    }

    var body: some View {
        listContent
            .safeAreaInset(edge: .top, spacing: 0) {
                topBars
            }
            .toolbar(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .task { await session.loadFolders() }
            .task(id: loadToken) { await session.loadFavorites() }
    }

    private var topBars: some View {
        VStack(spacing: 0) {
            folderStrip
            MineCategoryStrip(category: $session.favoriteCategory)
        }
    }

    @ViewBuilder
    private var folderStrip: some View {
        if session.isLoadingFolders, session.folders.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
        } else if let error = session.foldersError, session.folders.isEmpty {
            Text(error)
                .font(.caption)
                .foregroundStyle(.red)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
        } else if !session.folders.isEmpty {
            VStack(spacing: 0) {
                HorizontalCapsuleStrip(
                    items: session.folders,
                    selectedID: session.selectedFolderID,
                    title: { "\($0.displayName)·\($0.articleNum ?? 0)" },
                    id: \.id,
                    onSelect: { session.selectedFolderID = $0.id },
                    compact: true
                )
                Divider()
            }
            .background(Color(.systemBackground))
        }
    }

    private var listContent: some View {
        let items = session.favorites.items
        return AsyncPage(
            isLoading: session.favorites.isLoading,
            error: session.favorites.error,
            isEmpty: items.isEmpty,
            loadingTitle: "加载收藏…",
            emptyIcon: "star.slash",
            emptyTitle: "暂无收藏",
            retry: { Task { await session.loadFavorites(force: true) } }
        ) {
            List {
                ForEach(items) { item in
                    favoriteLink(item)
                        .buttonStyle(.plain)
                        .styledListRow()
                        .onAppear {
                            guard items.isLastItem(item) else { return }
                            Task { await session.loadMoreFavorites() }
                        }
                }
                AppUI.listLoadMoreFooter(
                    loadingMore: session.favorites.isLoadingMore,
                    exhausted: session.favorites.exhausted && session.favorites.loaded
                )
            }
            .plainContentList()
        }
    }

    @ViewBuilder
    private func favoriteLink(_ item: FavoriteItem) -> some View {
        let row = LibraryRow(
            title: item.displayTitle,
            author: item.author ?? item.contentType,
            imagePath: item.imagePath,
            subtitle: item.collectTime,
            coverAspectRatio: CoverAspect.ratio(modelID: item.modelID)
        )
        if item.isSeries {
            NavigationLink(value: item.asSeriesSummary) { row }
        } else {
            NavigationLink(value: item.asArticleSummary) { row }
        }
    }
}
