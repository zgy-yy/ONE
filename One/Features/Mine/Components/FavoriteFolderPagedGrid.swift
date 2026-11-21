import SwiftUI

/// 收藏夹详情：双列网格 + 分页加载（复用 `PagedListState`）。
struct FavoriteFolderPagedGrid<Cell: View>: View {
    let state: PagedListState<FavoriteItem>
    let loadingTitle: String
    let emptyTitle: String
    let retry: () -> Void
    let onRefresh: () async -> Void
    let loadMore: () -> Void
    @ViewBuilder let cell: (FavoriteItem) -> Cell

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    var body: some View {
        AsyncPage(
            isLoading: state.isLoading,
            error: state.error,
            isEmpty: state.isEmpty,
            loadingTitle: loadingTitle,
            emptyIcon: "bookmark.slash",
            emptyTitle: emptyTitle,
            retry: retry
        ) {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(state.items) { item in
                        cell(item)
                            .onAppear {
                                guard state.items.isLastItem(item) else { return }
                                loadMore()
                            }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

                AppUI.listLoadMoreFooter(
                    loadingMore: state.isLoadingMore,
                    exhausted: state.exhausted
                )
                .padding(.bottom, 8)
            }
            .refreshable { await onRefresh() }
        }
    }
}