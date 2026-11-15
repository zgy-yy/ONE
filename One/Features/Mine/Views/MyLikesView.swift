import SwiftUI

/// 我喜欢的内容列表。
struct MyLikesView: View {
    @Bindable private var session = MineLibrarySession.shared

    var body: some View {
        listContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .safeAreaInset(edge: .top, spacing: 0) {
                MineCategoryStrip(category: $session.likeCategory)
            }
            .toolbar(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .task(id: session.likeCategory) {
                await session.loadLikes()
            }
    }

    @ViewBuilder
    private var listContent: some View {
        let items = session.likes.items
        if session.likes.isLoading, items.isEmpty {
            AppUI.loading("加载喜欢…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = session.likes.error, items.isEmpty {
            AppUI.loadFailure(message: error) {
                Task { await session.loadLikes(force: true) }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if items.isEmpty {
            AppUI.emptyState(icon: "heart.slash", title: "暂无喜欢")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(items) { item in
                    NavigationLink(value: item.asArticleSummary) {
                        LibraryRow(
                            title: item.displayTitle,
                            author: item.author,
                            imagePath: item.imagePath,
                            subtitle: item.publishedAt
                        )
                    }
                    .buttonStyle(.plain)
                    .styledListRow()
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
}
