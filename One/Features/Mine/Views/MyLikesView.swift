import SwiftUI

/// 我喜欢的内容列表。
struct MyLikesView: View {
    @Bindable private var session = MineLibrarySession.shared

    var body: some View {
        listContent
            .safeAreaInset(edge: .top, spacing: 0) {
                MineCategoryStrip(category: $session.likeCategory)
            }
            .toolbar(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .task(id: session.likeCategory) {
                await session.loadLikes()
            }
    }

    private var listContent: some View {
        // 喜欢接口一次返回，无分页；触底 loadMore 为空操作。
        PagedAsyncList(
            state: session.likes,
            loadingTitle: "加载喜欢…",
            emptyIcon: "heart.slash",
            emptyTitle: "暂无喜欢",
            retry: { Task { await session.loadLikes(force: true) } },
            loadMore: {},
            row: likeRow
        )
    }

    private func likeRow(_ item: UserLikeItem) -> some View {
        LibraryRow(
            title: item.displayTitle,
            author: item.author,
            imagePath: item.imagePath,
            subtitle: item.publishedAt,
            coverAspectRatio: item.modelID == ContentCategory.ModelID.graphic
                ? CoverAspect.portrait
                : CoverAspect.landscape
        )
        .hiddenNavigationLink(value: item.asArticleSummary)
        .styledListRow()
    }
}
