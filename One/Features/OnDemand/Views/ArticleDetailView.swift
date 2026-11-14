import SwiftUI

/// 点播详情：顶栏固定播放器，其下 `ScrollView` 承载全部文稿信息。
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
        .navigationTitle(session.detail?.displayTitle ?? article.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: article.id) { await session.load(articleID: article.id) }
    }

    private var contentLayout: some View {
        VStack(spacing: 0) {
            videoSection
            ScrollView {
                ArticleDetailBodyView(detail: session.detail, summary: article)
                    .padding(.horizontal)
                    .padding(.vertical, 16)
            }
        }
    }

    @ViewBuilder
    private var videoSection: some View {
        if let url = session.playURL {
            ArticleVideoPlayer(url: url)
        } else if session.detail != nil {
            ContentUnavailableView {
                Label("无法播放", systemImage: "play.slash")
            } description: {
                Text("详情中未找到 video_file / video_hls，或缺少 one_video CDN")
            }
            .padding()
        }
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