import Foundation

/// `my/getUserLikeList` 列表项。
struct UserLikeItem: Decodable, Identifiable, Hashable {
    let id: Int
    let articleID: Int?
    let title: String?
    let thumb: String?
    let thumbTiny: String?
    let modelID: Int?
    let author: String?
    let publishedAt: String?

    var displayTitle: String {
        title?.nonEmpty ?? "内容 \(articleID ?? id)"
    }

    var imagePath: String? {
        OneThumbPath.preferred(thumb: thumb, thumbnail: thumbTiny)
    }

    /// 详情用 `article_id`，不是喜欢记录 id。
    var asArticleSummary: ArticleSummary {
        ArticleSummary(
            id: articleID ?? id,
            title: title,
            thumb: thumb,
            author: author,
            publishedAt: publishedAt,
            modelID: modelID,
            summary: nil
        )
    }

    enum CodingKeys: String, CodingKey {
        case id, title, thumb, author
        case articleID = "article_id"
        case thumbTiny = "thumb_tiny"
        case modelID = "model_id"
        case publishedAt = "published_at"
    }
}

struct UserLikeListPayload: Decodable {
    let list: [UserLikeItem]?
    let isMore: Int?

    var items: [UserLikeItem] { list ?? [] }
    var hasMore: Bool { isMore == 1 }

    enum CodingKeys: String, CodingKey {
        case list
        case isMore = "is_more"
    }
}

/// `my/getCollectFolderListByPage` 收藏夹。
struct CollectFolder: Decodable, Identifiable, Hashable {
    let id: Int
    let folderName: String?
    let articleNum: Int?

    var displayName: String {
        folderName?.nonEmpty ?? "收藏夹 \(id)"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case folderName = "folder_name"
        case articleNum = "article_num"
    }
}

/// `my/favorites` 列表项。
struct FavoriteItem: Decodable, Identifiable, Hashable {
    let id: Int
    let modelID: Int?
    let seriesCategory: Int?
    let title: String?
    let thumb: String?
    let thumbnail: String?
    let author: String?
    let collectTime: String?
    let contentType: String?

    var displayTitle: String {
        title?.nonEmpty ?? "内容 \(id)"
    }

    var imagePath: String? {
        OneThumbPath.preferred(thumb: thumb, thumbnail: thumbnail)
    }

    var isSeries: Bool { (seriesCategory ?? 0) > 0 }

    var asArticleSummary: ArticleSummary {
        ArticleSummary(
            id: id,
            title: title,
            thumb: thumb,
            author: author,
            publishedAt: nil,
            modelID: modelID,
            summary: nil
        )
    }

    var asSeriesSummary: SeriesSummary {
        SeriesSummary(
            id: id,
            title: title,
            author: author,
            thumb: thumb,
            thumbnail: thumbnail
        )
    }

    enum CodingKeys: String, CodingKey {
        case id, title, thumb, thumbnail, author
        case modelID = "model_id"
        case seriesCategory = "series_category"
        case collectTime = "collect_time"
        case contentType = "content_type"
    }
}

struct FavoritesPayload: Decodable {
    let list: [FavoriteItem]?
    let hasMore: Int?

    var items: [FavoriteItem] { list ?? [] }
    var canLoadMore: Bool { hasMore == 1 }

    enum CodingKeys: String, CodingKey {
        case list
        case hasMore = "has_more"
    }
}

/// `demand_activity/myRecordCounts`。
struct MyRecordCounts: Decodable {
    let winRecordCount: Int?

    enum CodingKeys: String, CodingKey {
        case winRecordCount = "win_record_count"
    }
}
