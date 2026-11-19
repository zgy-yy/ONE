import SwiftUI

/// 文章详情底部评论 sheet（阅读 / 写真漫画 / 点播等共用）。
struct ArticleCommentsSheet: View {
    @Bindable var session: ArticleDetailSession
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                ArticleDetailCommentsSection(session: session)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
            .navigationTitle("评论")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { isPresented = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .task {
            await session.loadComments()
        }
    }
}
