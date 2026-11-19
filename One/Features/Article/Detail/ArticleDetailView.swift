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
        case ContentCategory.ModelID.series, ContentCategory.ModelID.radio:
            StandardArticleDetailView(article: article, style: .content)
        default:
            StandardArticleDetailView(article: article, style: .media)
        }
    }
}
