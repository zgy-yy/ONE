import SwiftUI

/// 文章详情入口：按 `model_id` 分发。
struct ArticleDetailView: View {
    let article: ArticleSummary

    var body: some View {
        switch article.modelID {
        case ContentCategory.ModelID.graphic:
            GraphicArticleDetailView(article: article)
        case ContentCategory.ModelID.reading:
            StandardArticleDetailView(article: article, style: .reading)
        case ContentCategory.ModelID.series:
            StandardArticleDetailView(article: article, style: .content)
        case ContentCategory.ModelID.radio:
            StandardArticleDetailView(article: article, style: .radio)
        case ContentCategory.ModelID.film:
            StandardArticleDetailView(article: article, style: .film)
        default:
            StandardArticleDetailView(article: article, style: .media)
        }
    }
}
