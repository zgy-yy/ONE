import SwiftUI

/// 写真 / 漫画详情：演员单独一行，日期与出品分居两侧，互动含评论。
struct SeriesArticleDetailView: View {
    let article: ArticleSummary

    var body: some View {
        ArticleDetailShell(article: article, placeholderAspect: CoverAspect.landscape) { session, actions in
            if let detail = session.detail {
                VStack(alignment: .leading, spacing: 12) {
                    ArticleDetailTitle(detail: detail)

                    if let actor = ArticleFormat.nonEmpty(detail.actor) {
                        ArticleDetailIconLabel.actor(actor)
                    }

                    HStack(alignment: .center, spacing: 12) {
                        if let date = ArticleFormat.dateOnly(from: detail.publishedAt) {
                            ArticleDetailDateLabel(date: date)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        if let author = ArticleFormat.nonEmpty(detail.author) {
                            ArticleDetailIconLabel.publisher(author)
                                .frame(maxWidth: .infinity, alignment: .trailing)
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
                        Spacer()
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
