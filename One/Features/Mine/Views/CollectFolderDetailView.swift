import SwiftUI

/// 单个收藏夹内的收藏内容（双列卡片）。
struct CollectFolderDetailView: View {
    let route: CollectFolderRoute

    @Bindable private var session = MineLibrarySession.shared

    var body: some View {
        FavoriteFolderPagedGrid(
            state: session.favorites,
            loadingTitle: "加载收藏…",
            emptyTitle: "暂无收藏",
            retry: { Task { await session.loadFavorites(force: true) } },
            onRefresh: { await session.loadFavorites(force: true) },
            loadMore: { Task { await session.loadMoreFavorites() } },
            cell: favoriteCell
        )
        .background(Color(.systemGroupedBackground))
        .navigationTitle(route.folderName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .task(id: route.folderID) {
            session.enterFolder(id: route.folderID)
            await session.loadFavorites()
        }
    }

    private func favoriteCell(_ item: FavoriteItem) -> some View {
        libraryNavigationLink(
            isSeries: item.isSeries,
            article: item.asArticleSummary,
            series: item.asSeriesSummary
        ) {
            FavoriteItemRow(item: item)
        }
        .buttonStyle(.plain)
    }
}