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
        let items = session.likes.items
        return AsyncPage(
            isLoading: session.likes.isLoading,
            error: session.likes.error,
            isEmpty: items.isEmpty,
            loadingTitle: "加载喜欢…",
            emptyIcon: "heart.slash",
            emptyTitle: "暂无喜欢",
            retry: { Task { await session.loadLikes(force: true) } }
        ) {
            List {
                ForEach(items) { item in
                    NavigationLink(value: item.asArticleSummary) {
                        LibraryRow(
                            title: item.displayTitle,
                            author: item.author,
                            imagePath: item.imagePath,
                            subtitle: item.publishedAt,
                            coverAspectRatio: CoverAspect.ratio(modelID: item.modelID)
                        )
                    }
                    .buttonStyle(.plain)
                    .styledListRow()
                }
            }
            .plainContentList()
        }
    }
}
