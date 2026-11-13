import SwiftUI

/// 点播稿件详情：先 `article/detail` 再拼 `one_video` 播放（与 one-web 调试台一致）。
struct ArticleDetailView: View {
    let article: ArticleSummary

    @State private var session = ArticleDetailSession()

    var body: some View {
        Group {
            if session.isLoading, session.detail == nil {
                AppUI.loading("加载详情…")
            } else if let error = session.error, session.detail == nil {
                AppUI.loadFailure(message: error) {
                    Task { await session.load(articleID: article.id) }
                }
            } else {
                detailScroll
            }
        }
        .fillPage()
        .navigationTitle(session.detail?.displayTitle ?? article.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: article.id) { await session.load(articleID: article.id) }
    }

    private var detailScroll: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                playerSection
                heroThumb
                metaSection
                if let body = session.detail?.displayBody {
                    Text(body)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private var playerSection: some View {
        if let url = session.playURL {
            ArticleVideoPlayer(url: url)
        } else if session.detail != nil {
            ContentUnavailableView {
                Label("无法播放", systemImage: "play.slash")
            } description: {
                Text("详情中未找到 video_file / video_hls，或缺少 one_video CDN")
            }
        }
    }

    @ViewBuilder
    private var heroThumb: some View {
        let path = session.detail?.thumb ?? article.thumb
        if path != nil {
            OneCoverImage(
                path: path,
                size: CGSize(width: 120, height: 160)
            )
        }
    }

    private var metaSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(session.detail?.displayTitle ?? article.displayTitle)
                .font(.title2.weight(.semibold))
            if let author = session.detail?.author ?? article.author, !author.isEmpty {
                Text(author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let publishedAt = session.detail?.publishedAt ?? article.publishedAt, !publishedAt.isEmpty {
                Text(publishedAt)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
