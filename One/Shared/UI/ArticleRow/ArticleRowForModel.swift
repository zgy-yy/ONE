import SwiftUI

/// 按接口 `model_id` 选择列表行（首页日更等混合流）。
enum ArticleRowForModel {
    @ViewBuilder
    static func view(
        for article: ArticleSummary,
        showsDate: Bool = true,
        showsDescription: Bool = false
    ) -> some View {
        switch article.modelID {
        case ContentCategory.ModelID.graphic:
            PortraitArticleCard(
                article: article,
                showsDate: showsDate,
                showsDescription: showsDescription
            )
        case ContentCategory.ModelID.reading:
            ReadingArticleRow(article: article, showsDate: showsDate)
        case ContentCategory.ModelID.film:
            FilmArticleRow(article: article, showsDate: showsDate)
        case ContentCategory.ModelID.radio:
            RadioArticleRow(article: article, showsDate: showsDate)
        case ContentCategory.ModelID.vod:
            VodArticleRow(article: article, showsDate: showsDate)
        case ContentCategory.ModelID.series:
            // 首页日更里写真 / 漫画是单篇，不用系列章节行。
            ReadingArticleRow(article: article, showsDate: showsDate)
        default:
            VodArticleRow(article: article, showsDate: showsDate)
        }
    }
}
