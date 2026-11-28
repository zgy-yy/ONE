import SwiftUI

/// 阅读详情：方形封面；日期紧跟作者；评论在正文前。
struct ReadingArticleDetailView: View {
    let article: ArticleSummary

    var body: some View {
        ArticleDetailShell(article: article, placeholderAspect: CoverAspect.square) { session, actions in
            if let detail = session.detail {
                VStack(alignment: .leading, spacing: 12) {
                    ArticleDetailTitle(detail: detail)
                    HStack(alignment: .center, spacing: 12) {
                        if let author = ArticleFormat.nonEmpty(detail.author) {
                            ArticleDetailIconLabel.publisher(author)
                        }
                        Spacer()
                        if let date = ArticleFormat.dateOnly(from: detail.publishedAt) {
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
