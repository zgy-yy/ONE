import Foundation

// MARK: - 喜欢

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
    let likeNumber: Int?
    let isLike: Int?

    var isLiked: Bool { (isLike ?? 1) == 1 }

    var displayTitle: String {
        title?.nonEmpty ?? "内容 \(articleID ?? id)"
    }

    var imagePath: String? {
        ImagePath.preferred(thumb: thumb, thumbnail: thumbTiny)
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
            summary: nil,
            likeNumber: likeNumber,
            isLike: isLike ?? 1
        )
    }

    enum CodingKeys: String, CodingKey {
        case id, title, thumb, author
        case articleID = "article_id"
        case thumbTiny = "thumb_tiny"
        case modelID = "model_id"
        case publishedAt = "published_at"
        case likeNumber = "like_number"
        case isLike = "is_like"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        articleID = try c.decodeIfPresent(Int.self, forKey: .articleID)
        title = try c.decodeIfPresent(String.self, forKey: .title)
        thumb = try c.decodeIfPresent(String.self, forKey: .thumb)
        thumbTiny = try c.decodeIfPresent(String.self, forKey: .thumbTiny)
        modelID = try c.decodeIfPresent(Int.self, forKey: .modelID)
        author = try c.decodeIfPresent(String.self, forKey: .author)
        publishedAt = try c.decodeIfPresent(String.self, forKey: .publishedAt)
        likeNumber = JSONFlex.int(c, .likeNumber)
        isLike = JSONFlex.int(c, .isLike)
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

// MARK: - 收藏夹

/// `my/getCollectFolderListByPage` 收藏夹。
struct CollectFolder: Decodable, Identifiable, Hashable {
    let id: Int
    let folderName: String?
    let articleNum: Int?
    let articleLikeNum: Int?
    let isDefault: Bool
    let thumb: String?
    let thumbnail: String?

    var displayName: String {
        folderName?.nonEmpty ?? "收藏夹 \(id)"
    }

    var imagePath: String? {
        ImagePath.preferred(thumb: thumb, thumbnail: thumbnail)
    }

    enum CodingKeys: String, CodingKey {
        case id, thumb, thumbnail
        case folderName = "folder_name"
        case articleNum = "article_num"
        case articleLikeNum = "article_like_num"
        case isDefault = "is_default"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        folderName = try c.decodeIfPresent(String.self, forKey: .folderName)
        thumb = try c.decodeIfPresent(String.self, forKey: .thumb)
        thumbnail = try c.decodeIfPresent(String.self, forKey: .thumbnail)
        articleNum = JSONFlex.int(c, .articleNum)
        articleLikeNum = JSONFlex.int(c, .articleLikeNum)
        isDefault = JSONFlex.int(c, .isDefault) == 1
    }
}

// MARK: - 夹内条目

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
    let publishedAt: String?
    let likeNumber: Int?
    let collectionNumber: Int?
    let contentType: String?
    let isLike: Int?
    let isCollected: Int?

    var displayTitle: String {
        title?.nonEmpty ?? "内容 \(id)"
    }

    var imagePath: String? {
        ImagePath.preferred(thumb: thumb, thumbnail: thumbnail)
    }

    var listCategory: ContentCategory {
        ContentCategory.forSearch(modelID: modelID, seriesCategory: seriesCategory)
    }

    /// 展示用：`content_type / 作者`。
    var typeAuthorLine: String {
        let type = contentType?.nonEmpty ?? listCategory.title
        if let author = author?.nonEmpty {
            return "\(type) / \(author)"
        }
        return type
    }

    var isSeries: Bool { (seriesCategory ?? 0) > 0 }

    var asArticleSummary: ArticleSummary {
        ArticleSummary(
            id: id,
            title: title,
            thumb: thumb,
            author: author ?? contentType,
            publishedAt: publishedAt,
            modelID: modelID,
            summary: nil,
            likeNumber: likeNumber,
            collectionNumber: collectionNumber,
            isLike: isLike,
            isCollected: isCollected ?? 1,
            seriesCategory: seriesCategory
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
        case publishedAt = "published_at"
        case likeNumber = "like_number"
        case collectionNumber = "collection_number"
        case contentType = "content_type"
        case isLike = "is_like"
        case isCollected = "is_collected"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        modelID = try c.decodeIfPresent(Int.self, forKey: .modelID)
        seriesCategory = try c.decodeIfPresent(Int.self, forKey: .seriesCategory)
        title = try c.decodeIfPresent(String.self, forKey: .title)
        thumb = try c.decodeIfPresent(String.self, forKey: .thumb)
        thumbnail = try c.decodeIfPresent(String.self, forKey: .thumbnail)
        author = try c.decodeIfPresent(String.self, forKey: .author)
        collectTime = try c.decodeIfPresent(String.self, forKey: .collectTime)
        publishedAt = try c.decodeIfPresent(String.self, forKey: .publishedAt)
        contentType = try c.decodeIfPresent(String.self, forKey: .contentType)
        likeNumber = JSONFlex.int(c, .likeNumber)
        collectionNumber = JSONFlex.int(c, .collectionNumber)
        isLike = JSONFlex.int(c, .isLike)
        isCollected = JSONFlex.int(c, .isCollected)
    }
}

// MARK: - 导航与分页

/// 进入某收藏夹详情。
struct CollectFolderRoute: Hashable {
    let folderID: Int
    let folderName: String
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
