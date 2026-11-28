import SwiftUI

/// 详情页共用动作：页面本身负责弹层与播放，正文只调用 UI 动作。
struct ArticleDetailActions {
    let comments: () -> Void
    let collect: () -> Void
    let like: () -> Void
    let play: () -> Void
    let download: (ArticlePlayURL.DownloadOption) -> Void
}

/// 非图文详情共用外壳：封面、加载、评论弹层、收藏夹与下载列表。
/// 具体正文由阅读 / 写真漫画 / 电台 / 影视 / 点播各自 Detail 文件提供。
struct ArticleDetailShell<Content: View>: View {
    let article: ArticleSummary
    let placeholderAspect: CGFloat
    @ViewBuilder var content: (ArticleDetailSession, ArticleDetailActions) -> Content

    @State private var session = ArticleDetailSession()
    @State private var showsComments = false
    @State private var collectMoveContext: CollectFolderMoveContext?
    @State private var showsDownloadList = false

    var body: some View {
        ArticleDetailChrome(article: article, session: session) {
            ArticleDetailScrollLayout(
                coverPath: session.detail?.thumb ?? article.thumb,
                placeholderAspect: placeholderAspect
            ) {
                content(session, actions)
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
        .sheet(isPresented: $showsDownloadList) {
            NavigationStack {
                VideoDownloadListView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("完成") { showsDownloadList = false }
                        }
                    }
            }
            .presentationDragIndicator(.visible)
        }
    }

    private var actions: ArticleDetailActions {
        ArticleDetailActions(
            comments: { showsComments = true },
            collect: {
                Task {
                    collectMoveContext = await ArticleCollectAction.handleInDetail(
                        article: article,
                        syncDetail: { session.syncReactionsFromStore() }
                    )
                }
            },
            like: { Task { await session.toggleLike() } },
            play: {
                guard let url = session.playURL else { return }
                ArticleVideoPresenter.present(url: url)
            },
            download: queueDownload
        )
    }

    private func queueDownload(_ option: ArticlePlayURL.DownloadOption) {
        guard let detail = session.detail else { return }
        let result = VideoDownloadSession.shared.enqueue(
            title: detail.displayVideoName,
            coverPath: detail.thumb ?? article.thumb,
            qualityLabel: option.title,
            remoteURL: option.url
        )
        showsDownloadList = result == .started || result == .duplicate
    }
}
