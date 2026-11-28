import SwiftUI

/// 影视详情：可播放、可下载；期数与出品分居两侧；统计和互动分两行。
struct FilmArticleDetailView: View {
    let article: ArticleSummary

    var body: some View {
        ArticleDetailShell(article: article, placeholderAspect: CoverAspect.landscape) { session, actions in
            if let detail = session.detail {
                VStack(alignment: .leading, spacing: 12) {
                    ArticleDetailTitle(detail: detail)
                    ArticleDetailPlayDownloadRow(
                        canPlay: session.playURL != nil,
                        videoDownloadOptions: session.videoDownloadOptions,
                        onPlay: actions.play,
                        onPickDownload: actions.download
                    )

                    if let actor = ArticleFormat.nonEmpty(detail.actor) {
                        ArticleDetailIconLabel.actor(actor)
                    }

                    HStack(alignment: .center, spacing: 12) {
                        if let vol = detail.vol {
                            ArticleDetailIconLabel.volumeIssue(vol)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        if let author = ArticleFormat.nonEmpty(detail.author) {
                            ArticleDetailIconLabel.publisher(author)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }

                    ArticleDetailVideoSpecsRow(detail: detail)

                    HStack(spacing: 16) {
                        if let date = ArticleFormat.dateOnly(from: detail.publishedAt) {
                            ArticleDetailDateLabel(date: date)
                        }
                        Spacer(minLength: 8)
                        ArticleDetailDownloadShareStats(detail: detail)
                    }

                    HStack(spacing: 20) {
                        ArticleDetailCollectLikeRow(
                            article: article,
                            detail: detail,
                            onCollect: actions.collect,
                            onLike: actions.like
                        )
                        Spacer(minLength: 0)
                        ArticleDetailCommentButton(
                            count: detail.commentNumber ?? 0,
                            action: actions.comments
                        )
                    }

                    ArticleDetailSupplementaryContent(summary: article, detail: detail)
                }
            }
        }
    }
}
