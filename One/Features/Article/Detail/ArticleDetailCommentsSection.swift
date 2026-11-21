import SwiftUI

/// 评论列表内容（用于底部升起的 sheet）。
struct ArticleDetailCommentsSection: View {
    @Bindable var session: ArticleDetailSession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("评论")
                    .font(.headline)
                if let count = session.detail?.commentNumber {
                    Text(ArticleFormat.shortCount(count))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                CommentSortPicker(sort: $session.commentSort)
            }

            AsyncSection(
                isLoading: session.comments.isLoading,
                error: session.comments.error,
                isEmpty: session.comments.isEmpty,
                loadingTitle: "加载评论…",
                emptyTitle: "暂无评论",
                retry: {
                    Task { await session.loadComments(force: true) }
                }
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(session.comments.items) { comment in
                        CommentRow(
                            comment: comment,
                            loadReplies: { parent, sort in
                                await session.loadReplies(for: parent, sorting: sort)
                            }
                        )
                        .onAppear {
                            guard session.comments.items.isLastItem(comment) else { return }
                            Task { await session.loadMoreComments() }
                        }
                    }
                    AppUI.loadMoreFooter(
                        loadingMore: session.comments.isLoadingMore,
                        exhausted: session.comments.exhausted
                    )
                }
            }
        }
        .onChange(of: session.commentSort) { old, new in
            guard old != new else { return }
            Task { await session.reloadComments() }
        }
    }
}
