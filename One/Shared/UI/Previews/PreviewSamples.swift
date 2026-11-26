import Foundation
import SwiftUI

/// Xcode Preview 共用假数据（https 封面，不请求业务 API）。
///
/// 各 `#Preview` 从这里取 `ArticleSummary` / `ActorDetail` 即可，避免每个文件各写一份 URL。
enum PreviewSamples {

    // MARK: - 封面 URL

    enum ImageURL {
        /// 竖图 3:4
        static let portrait =
            "https://images.unsplash.com/photo-1529139578806-5813dffbe961?w=320&h=427&fit=crop"
        /// 横图 16:9
        static let landscape =
            "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=560&h=315&fit=crop"
        static let landscapeAlt =
            "https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=560&h=315&fit=crop"
        /// 图文竖图
        static let graphicPortrait =
            "https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400&h=533&fit=crop"
        static let readingWide =
            "https://images.unsplash.com/photo-1495446815901-a7297e633e8d?w=640&h=360&fit=crop"
    }

    // MARK: - 列表文章

    enum Article {
        static let graphic = ArticleSummary(
            id: 8101,
            title: "图文示例",
            thumb: ImageURL.landscape,
            author: "编辑部",
            publishedAt: "2024-06-18",
            modelID: ContentCategory.ModelID.graphic,
            summary: "简介占位",
            likeNumber: 120,
            collectionNumber: 45,
            views: 5_600,
            isLike: 0,
            isCollected: 0
        )

        /// 图文详情页 Preview 用。
        static let graphicDetailPage = ArticleSummary(
            id: 8401,
            title: "图文详情预览 · 标题居中",
            thumb: ImageURL.graphicPortrait,
            author: "摄影组",
            publishedAt: "2024-08-15",
            modelID: ContentCategory.ModelID.graphic,
            summary: "简介左对齐；作者与收藏、喜欢同一行。",
            likeNumber: 1_280,
            collectionNumber: 456,
            views: 88_000,
            isLike: 1,
            isCollected: 0
        )

        static let vod = ArticleSummary(
            id: 8102,
            title: "点播标题",
            thumb: ImageURL.readingWide,
            author: "出品方",
            publishedAt: "2024-01-01",
            modelID: ContentCategory.ModelID.vod,
            summary: "简介",
            coin: 6,
            originalCoin: 12,
            likeNumber: 88,
            collectionNumber: 12,
            views: 1_000,
            isLike: 0,
            isCollected: 0
        )

        static let vodDiscount = ArticleSummary(
            id: 8103,
            title: "点播 · 优惠价",
            thumb: ImageURL.landscape,
            author: "频道",
            publishedAt: "2023-12-01",
            modelID: ContentCategory.ModelID.vod,
            summary: nil,
            coin: 3,
            originalCoin: 18,
            likeNumber: 200,
            views: 3_200,
            isLike: 1,
            isCollected: 0
        )

        static let filmLong = ArticleSummary(
            id: 9001,
            title: "漫长的季节 · 全集回顾",
            thumb: ImageURL.landscape,
            author: "辛爽",
            publishedAt: "2024-03-15 12:00:00",
            modelID: ContentCategory.ModelID.film,
            summary: nil,
            likeNumber: 12_800,
            collectionNumber: 3_200,
            views: 1_413_682,
            isLike: 1,
            isCollected: 0,
            vol: 3
        )

        static let filmShort = ArticleSummary(
            id: 9002,
            title: "海边一日",
            thumb: ImageURL.landscapeAlt,
            author: "佚名",
            publishedAt: "2023-11-01",
            modelID: ContentCategory.ModelID.film,
            summary: nil,
            likeNumber: 256,
            collectionNumber: 890,
            views: 52_000,
            isLike: 0,
            isCollected: 1,
            vol: 1
        )

        static let radio = ArticleSummary(
            id: 9101,
            title: "午夜电台 · 城市漫步",
            thumb: ImageURL.landscape,
            author: "小林",
            publishedAt: "2024-05-20",
            modelID: ContentCategory.ModelID.radio,
            summary: nil,
            likeNumber: 3_200,
            collectionNumber: 512,
            isLike: 1,
            isCollected: 0,
            vol: 128
        )

        static let radioShort = ArticleSummary(
            id: 9102,
            title: "短标题一期",
            thumb: ImageURL.landscapeAlt,
            author: "电台编辑部",
            publishedAt: "2023-09-01",
            modelID: ContentCategory.ModelID.radio,
            summary: nil,
            likeNumber: 88,
            isLike: 0,
            isCollected: 1,
            vol: 12
        )

        static let reading = ArticleSummary(
            id: 8201,
            title: "阅读 · 长篇标题示例",
            thumb: ImageURL.readingWide,
            author: "作者",
            publishedAt: "2024-05-01",
            modelID: ContentCategory.ModelID.reading,
            summary: "两行摘要示例",
            views: 890,
            isLike: 0,
            isCollected: 0
        )

        static var vodDetail: ArticleDetail {
            let json = """
                {
                  "id": 8102,
                  "video_name": "点播详情预览",
                  "title": "点播详情预览",
                  "actor": "演员 A",
                  "author": "出品方",
                  "number": "ABC-001",
                  "coin": 6,
                  "original_coin": 12,
                  "length": "129分钟",
                  "size": "2.3G",
                  "quality": "1920x1080",
                  "like_number": 88,
                  "collection_number": 12,
                  "reply_counts": 5,
                  "download_count": 100,
                  "is_like": 0,
                  "is_collected": 1
                }
                """
            return try! JSONDecoder().decode(ArticleDetail.self, from: Data(json.utf8))
        }

        /// 多图预览横滑用。
        static let galleryPaths = [
            ImageURL.landscape,
            ImageURL.landscapeAlt,
            ImageURL.readingWide,
        ]
    }

    // MARK: - 演员

    enum Actor {
        static let coverURL = ImageURL.portrait

        static let detail: ActorDetail = {
            let json = """
                {
                  "id": 168,
                  "main_name": "预览演员",
                  "japanese_name": "瀬戸 環奈",
                  "nickname": "环神",
                  "alias_name": "别名 A",
                  "thumb": "\(coverURL)",
                  "thumbnail": "\(coverURL)",
                  "height": "165",
                  "bust_waist_hip": "88-58-86",
                  "cup_size": "D",
                  "birth_date": "1998-05-20",
                  "age": "27",
                  "article_num": 42,
                  "photo_num": 18,
                  "comment_num": 6,
                  "is_collected": 0,
                  "desc": "Preview 示例简介。"
                }
                """
            return try! JSONDecoder().decode(ActorDetail.self, from: Data(json.utf8))
        }()

        static var summary: ActorSummary { detail.asSummary }
    }
}

/// 列表行 Preview 常用包装（与 `FilmArticleRow` 等一致）。
enum PreviewListChrome {
    static func list<Row: View>(@ViewBuilder rows: () -> Row) -> some View {
        List { rows() }.plainContentList()
    }
}
