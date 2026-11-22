import SwiftUI

/// 标准文章详情（阅读 / 写真漫画 / 电台 / 点播影视）。
struct StandardArticleDetailView: View {
    let article: ArticleSummary
    let style: ArticleDetailStyle

    @State private var session = ArticleDetailSession()
    @State private var showsComments = false
    @State private var collectMoveContext: CollectFolderMoveContext?

    var body: some View {
        ArticleDetailChrome(article: article, session: session) {
            ArticleDetailScrollLayout(
                coverPath: session.detail?.thumb ?? article.thumb,
                placeholderAspect: style.placeholderAspect
            ) {
                ArticleDetailBodyView(
                    detail: session.detail,
                    summary: article,
                    style: style,
                    canPlay: session.playURL != nil,
                    onPlay: style.showsPlay ? { startPlayback() } : nil,
                    onCommentsTap: { showsComments = true },
                    onCollect: {
                        Task {
                            collectMoveContext = await ArticleCollectAction.handleInDetail(
                                article: article,
                                syncDetail: { session.syncReactionsFromStore() }
                            )
                        }
                    },
                    onLike: { Task { await session.toggleLike() } }
                )
                .padding(.horizontal)
                .padding(.vertical, 16)

                ArticlePlayURLFooter(entries: session.playURLEntries)
                    .padding(.horizontal)
            }
        }
        .sheet(isPresented: $showsComments) {
            ArticleCommentsSheet(session: session, isPresented: $showsComments)
        }
        .articleCollectMoveFlow($collectMoveContext) {
            session.syncReactionsFromStore()
        }
    }

    private func startPlayback() {
        guard let url = session.playURL else { return }
        ArticleVideoPresenter.present(url: url, quality: session.detail?.quality)
    }
}