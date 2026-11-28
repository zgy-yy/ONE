import SwiftUI

/// 文章详情入口：每个内容类型使用自己的 Detail 文件。
struct ArticleDetailView: View {
    let article: ArticleSummary

    var body: some View {
        switch article.modelID {
        case ContentCategory.ModelID.graphic:
            GraphicArticleDetailView(article: article)
        case ContentCategory.ModelID.reading:
            ReadingArticleDetailView(article: article)
        case ContentCategory.ModelID.series:
            SeriesArticleDetailView(article: article)
        case ContentCategory.ModelID.radio:
            RadioArticleDetailView(article: article)
        case ContentCategory.ModelID.film:
            FilmArticleDetailView(article: article)
        case ContentCategory.ModelID.vod:
            VodArticleDetailView(article: article)
        default:
            ReadingArticleDetailView(article: article)
        }
    }
}
