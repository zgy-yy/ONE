import Foundation

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