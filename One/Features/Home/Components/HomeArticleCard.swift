import SwiftUI

/// 首页按月瀑布流中的图文卡片（文案居中）。
struct HomeArticleCard: View {
    let article: ArticleSummary

    var body: some View {
        HomeGraphicArticleView(article: article, textAlignment: .center, showsDescription: true)
    }
}

#Preview("首页月卡片") {
    List {
        MasonryLayout(columns: 2, spacing: 10) {
            HomeArticleCard(article: HomeArticleCardPreview.sample)
            HomeArticleCard(article: HomeArticleCardPreview.shortTitle)
        }
        .styledListRow()
    }
    .plainContentList()
}

private enum HomeArticleCardPreview {
    private static let coverA =
        "https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400&h=533&fit=crop"
    private static let coverB =
        "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=640&h=400&fit=crop"

    static let sample = ArticleSummary(
        id: 8301,
        title: "首页按月 · 标题最多两行",
        thumb: coverA,
        author: "摄影组",
        publishedAt: "2024-07-01",
        modelID: ContentCategory.ModelID.graphic,
        summary: "简介最多两行，封面按原始比例。",
        likeNumber: 888,
        collectionNumber: 120,
        isLike: 1,
        isCollected: 0
    )

    static let shortTitle = ArticleSummary(
        id: 8302,
        title: "短标题",
        thumb: coverB,
        author: "编辑",
        publishedAt: "2023-10-15",
        modelID: ContentCategory.ModelID.graphic,
        summary: nil,
        likeNumber: 42,
        collectionNumber: 5,
        isLike: 0,
        isCollected: 1
    )
}