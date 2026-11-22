import SwiftUI

/// 首页单日列表行：按 `model_id` 在图文 / 其他体裁间切换。
struct HomeArticleRow: View {
    let article: ArticleSummary
    var showsDescription: Bool = false

    var body: some View {
        Group {
            if article.modelID == ContentCategory.ModelID.graphic {
                HomeGraphicArticleView(article: article, showsDescription: showsDescription)
            } else {
                HomeFeedArticleView(article: article, showsDescription: showsDescription)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview("首页日行") {
    PreviewListChrome.list {
        HomeArticleRow(article: PreviewSamples.Article.graphic, showsDescription: true).styledListRow()
        HomeArticleRow(article: PreviewSamples.Article.vod, showsDescription: true).styledListRow()
    }
}
