import SwiftUI

/// 点播详情：封面顶到安全区外；无导航标题；标题下「播放」进入横屏全屏播放。
struct ArticleDetailView: View {
    let article: ArticleSummary

    @State private var session = ArticleDetailSession()

    var body: some View {
        Group {
            switch loadState {
            case .loading:
                AppUI.loading("加载详情…")
            case .failed(let message):
                AppUI.loadFailure(message: message) {
                    Task { await session.load(articleID: article.id) }
                }
            case .content:
                contentLayout
            }
        }
        .fillPage()
        .toolbar(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task(id: article.id) { await session.load(articleID: article.id) }
    }

    private var contentLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ArticleDetailCover(path: session.detail?.thumb ?? article.thumb)

                ArticleDetailBodyView(
                    detail: session.detail,
                    summary: article,
                    canPlay: session.playURL != nil,
                    onPlay: {
                        if let url = session.playURL {
                            ArticleVideoPresenter.present(url: url)
                        }
                    }
                )
                .padding(.horizontal)
                .padding(.vertical, 16)
            }
        }
        // 封面从屏幕顶端起算（含刘海/状态栏），导航栏浮在封面上。
        .ignoresSafeArea(edges: .top)
    }

    private enum LoadState {
        case loading
        case failed(String)
        case content
    }

    private var loadState: LoadState {
        if session.isLoading, session.detail == nil { return .loading }
        if let error = session.error, session.detail == nil { return .failed(error) }
        return .content
    }
}
