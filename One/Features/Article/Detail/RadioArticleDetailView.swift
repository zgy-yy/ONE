import SwiftUI

/// 电台详情：日期在出品右侧；评论在正文前；统计与互动同一行。
struct RadioArticleDetailView: View {
    let article: ArticleSummary

    var body: some View {
        ArticleDetailShell(article: article, placeholderAspect: CoverAspect.landscape) { session, actions in
            if let detail = session.detail {
                VStack(alignment: .leading, spacing: 12) {
                    ArticleDetailTitle(detail: detail)

                    HStack(alignment: .center, spacing: 12) {
                        if let actor = ArticleFormat.nonEmpty(detail.actor) {
                            ArticleDetailIconLabel.actor(actor)
                        }
                        if let author = ArticleFormat.nonEmpty(detail.author) {
                            ArticleDetailIconLabel.publisher(author)
                        }
                        if let date = ArticleFormat.dateOnly(from: detail.publishedAt) {
                            Spacer(minLength: 8)
                            ArticleDetailDateLabel(date: date)
                        }
                    }

                    ArticleDetailVideoSpecsRow(detail: detail)

                    HStack(spacing: 20) {
                        ArticleDetailCollectLikeRow(
                            article: article,
                            detail: detail,
                            onCollect: actions.collect,
                            onLike: actions.like
                        )
                        ArticleDetailDownloadShareStats(detail: detail)
                    }

                    ArticleDetailCommentRow(
                        count: detail.commentNumber,
                        action: actions.comments
                    )

                    ArticleDetailSupplementaryContent(summary: article, detail: detail)
                }
            }
        }
    }
}
