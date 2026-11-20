import SwiftUI

/// `AsyncPage` + `List` + 触底加载更多：搜索 / 喜欢 / 收藏等分页列表共用。
struct PagedAsyncList<Item: Identifiable, Row: View>: View where Item.ID: Hashable {
    let state: PagedListState<Item>
    var loadingTitle: String = "加载中…"
    var emptyIcon: String = "circle.slash"
    var emptyTitle: String = "无内容"
    let retry: () -> Void
    var onRefresh: (() async -> Void)? = nil
    let loadMore: () -> Void
    @ViewBuilder var row: (Item) -> Row

    var body: some View {
        AsyncPage(
            isLoading: state.isLoading,
            error: state.error,
            isEmpty: state.isEmpty,
            loadingTitle: loadingTitle,
            emptyIcon: emptyIcon,
            emptyTitle: emptyTitle,
            retry: retry
        ) {
            contentList
        }
    }

    @ViewBuilder
    private var contentList: some View {
        let list = List {
            ForEach(state.items) { item in
                row(item)
                    .onAppear {
                        guard state.items.isLastItem(item) else { return }
                        loadMore()
                    }
            }
            AppUI.listLoadMoreFooter(
                loadingMore: state.isLoadingMore,
                exhausted: state.exhausted
            )
        }

        if let onRefresh {
            list.plainContentList(onRefresh: onRefresh)
        } else {
            list.plainContentList()
        }
    }
}
