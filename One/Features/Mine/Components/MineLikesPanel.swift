import SwiftUI

/// 喜欢列表（嵌入「我的」Tab）。
struct MineLikesPanel: View {
    @Bindable private var session = MineLibrarySession.shared

    var body: some View {
        VStack(spacing: 0) {
            MineCategoryStrip(category: $session.likeCategory)

            PagedAsyncList(
                state: session.likes,
                loadingTitle: "加载喜欢…",
                emptyIcon: "heart.slash",
                emptyTitle: "暂无喜欢",
                retry: { Task { await session.loadLikes(force: true) } },
                onRefresh: { await session.loadLikes(force: true) },
                loadMore: {},
                row: likeRow
            )
        }
        .task(id: session.likeCategory) {
            await session.loadLikes()
        }
    }

    private func likeRow(_ item: UserLikeItem) -> some View {
        UserLikeRow(item: item, session: session)
        .hiddenNavigationLink(value: item.asArticleSummary)
        .styledListRow()
    }
}