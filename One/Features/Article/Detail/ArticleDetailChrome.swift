import SwiftUI

/// 文章详情共用壳：加载门闩 + 导航栏样式 + 拉详情。
struct ArticleDetailChrome<Content: View>: View {
    let article: ArticleSummary
    @Bindable var session: ArticleDetailSession
    @ViewBuilder var content: () -> Content

    var body: some View {
        DetailLoadGate(
            isLoading: session.isLoading,
            error: session.error,
            hasContent: session.detail != nil,
            loadingTitle: "加载详情…",
            retry: { Task { await session.load(articleID: article.id) } }
        ) {
            content()
        }
        .toolbar(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task(id: article.id) {
            await session.load(articleID: article.id)
        }
    }
}
