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
    List {
        HomeArticleRow(article: HomeArticleRowPreview.graphic, showsDescription: true)
        HomeArticleRow(article: HomeArticleRowPreview.vod, showsDescription: true)
    }
    .plainContentList()
}

private enum HomeArticleRowPreview {
    private static let graphicThumb =
        "https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400&h=533&fit=crop"
    private static let wideThumb =
        "https://images.unsplash.com/photo-1495446815901-a7297e633e8d?w=640&h=360&fit=crop"

    static let graphic = ArticleSummary(
        id: 8101,
        title: "图文",
        thumb: graphicThumb,
        author: "编辑部",
        publishedAt: "2024-06-18",
        modelID: ContentCategory.ModelID.graphic,
        summary: "简介",
        likeNumber: 1,
        collectionNumber: 1,
        views: 5600,
        isLike: 0,
        isCollected: 0
    )

    static let vod = ArticleSummary(
        id: 8102,
        title: "点播标题",
        thumb: wideThumb,
        author: "出品方",
        publishedAt: "2024-01-01",
        modelID: ContentCategory.ModelID.vod,
        summary: "简介",
        likeNumber: 1,
        collectionNumber: 1,
        views: 1000,
        isLike: 0,
        isCollected: 0,
        vol: 2
    )
}
