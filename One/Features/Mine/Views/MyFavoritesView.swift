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
            TopCapsuleBar(
                items: session.folders,
                selectedID: session.selectedFolderID,
                title: { "\($0.displayName)·\($0.articleNum ?? 0)" },
                id: \.id,
                onSelect: { session.selectedFolderID = $0.id }
            )
        }
    }

    private var listContent: some View {
        PagedAsyncList(
            state: session.favorites,
            loadingTitle: "加载收藏…",
            emptyIcon: "star.slash",
            emptyTitle: "暂无收藏",
            retry: { Task { await session.loadFavorites(force: true) } },
            loadMore: { Task { await session.loadMoreFavorites() } },
            row: favoriteRow
        )
    }

    private func favoriteRow(_ item: FavoriteItem) -> some View {
        LibraryRow(
            title: item.displayTitle,
            author: item.author ?? item.contentType,
            imagePath: item.imagePath,
            subtitle: item.collectTime,
            coverAspectRatio: item.modelID == ContentCategory.ModelID.graphic
                ? CoverAspect.portrait
                : CoverAspect.landscape
        )
        .libraryNavigation(
            isSeries: item.isSeries,
            article: item.asArticleSummary,
            series: item.asSeriesSummary
        )
        .styledListRow()
    }
}
