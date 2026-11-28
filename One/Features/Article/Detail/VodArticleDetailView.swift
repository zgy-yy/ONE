import SwiftUI

/// 点播详情：可播放、可下载；演员/出品分居两侧；日期在「预览」标题左侧。
struct VodArticleDetailView: View {
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
                    ArticleDetailPriceNumberRow(detail: detail)

                    HStack(alignment: .center, spacing: 12) {
                        if let actor = ArticleFormat.nonEmpty(detail.actor) {
                            ArticleDetailIconLabel.actor(actor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        if let author = ArticleFormat.nonEmpty(detail.author) {
                            ArticleDetailIconLabel.publisher(author)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }

                    ArticleDetailVideoSpecsRow(detail: detail)

                    HStack(alignment: .center, spacing: 12) {
                        ArticleDetailDownloadShareStats(detail: detail)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ArticleDetailCollectLikeRow(
                            article: article,
                            detail: detail,
                            onCollect: actions.collect,
                            onLike: actions.like
                        )
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    if !detail.galleryPaths.isEmpty || detail.commentNumber != nil {
                        ArticleMultiplePicGallery(
                            paths: detail.galleryPaths,
                            commentCount: detail.commentNumber,
                            onCommentsTap: actions.comments,
                            headerDate: ArticleFormat.dateOnly(from: detail.publishedAt)
                        )
                    }

                    ArticleDetailSupplementaryContent(summary: article, detail: detail)
                }
            }
        }
    }
}
