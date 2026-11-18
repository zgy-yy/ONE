import SwiftUI

/// 按接口 `model_id` 选择列表行（首页日更等混合流）。
enum ArticleRowForModel {
    @ViewBuilder
    static func view(for article: ArticleSummary) -> some View {
        switch article.modelID {
        case ContentCategory.ModelID.graphic:
            HomeGraphicArticleRow(article: article)
        case ContentCategory.ModelID.reading:
            ReadingArticleRow(article: article)
        case ContentCategory.ModelID.film:
            FilmArticleRow(article: article)
        case ContentCategory.ModelID.radio:
            RadioArticleRow(article: article)
        case ContentCategory.ModelID.vod:
            VodArticleRow(article: article)
        default:
            VodArticleRow(article: article)
        }
    }
}
