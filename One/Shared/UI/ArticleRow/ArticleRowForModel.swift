import SwiftUI

/// 发现 / 搜索列表：按 `model_id` 选用对应 `*ArticleRow`（首页日更走 `HomeArticleRow`）。
enum ArticleRowForModel {
    @ViewBuilder
    static func view(for article: ArticleSummary) -> some View {
        switch article.modelID {
        case ContentCategory.ModelID.graphic:
            GraphicArticleCard(article: article)
        case ContentCategory.ModelID.reading:
            ReadingArticleRow(article: article)
        case ContentCategory.ModelID.film:
            FilmArticleRow(article: article)
        case ContentCategory.ModelID.radio:
            RadioArticleRow(article: article)
        case ContentCategory.ModelID.vod:
            VodArticleRow(article: article)
        case ContentCategory.ModelID.series:
            ReadingArticleRow(article: article)
        default:
            VodArticleRow(article: article)
        }
    }
}
