import SwiftUI

/// 文章详情：封面顶到安全区外；点「评论」从底部升起卡片展示评论列表。
struct ArticleDetailView: View {
    let article: ArticleSummary

    @State private var session = ArticleDetailSession()
    @State private var showsComments = false

    var body: some View {
        DetailLoadGate(
            isLoading: session.isLoading,
            error: session.error,
            hasContent: session.detail != nil,
            loadingTitle: "加载详情…",
            retry: { Task { await session.load(articleID: article.id) } }
        ) {
            contentLayout
        }
        .toolbar(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task(id: article.id) { await session.load(articleID: article.id) }
        .sheet(isPresented: $showsComments) {
            commentsSheet
        }
    }

    private var contentLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 优先用详情封面；尚未返回时退回列表摘要里的缩略图
                ArticleDetailCover(path: session.detail?.thumb ?? article.thumb)

                ArticleDetailBodyView(
                    detail: session.detail,
                    summary: article,
                    canPlay: session.playURL != nil,
                    onPlay: {
                        if let url = session.playURL {
                            ArticleVideoPresenter.present(url: url)
                        }
                    },
                    onCommentsTap: { showsComments = true }
                )
                .padding(.horizontal)
                .padding(.vertical, 16)
            }
        }
        // 封面从屏幕顶端起算（含刘海/状态栏），导航栏浮在封面上。
        .ignoresSafeArea(edges: .top)
    }

    private var commentsSheet: some View {
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
                    Button("完成") { showsComments = false }
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
