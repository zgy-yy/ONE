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
    let likeNumber: Int?
    let isLike: Int?

    var isLiked: Bool { (isLike ?? 1) == 1 }

    var displayTitle: String {
        title?.nonEmpty ?? "内容 \(articleID ?? id)"
    }

    var imagePath: String? {
        ImagePath.preferred(thumb: thumb, thumbnail: thumbTiny)
    }

    var listCategory: ContentCategory {
        ContentCategory.forSearch(modelID: modelID, seriesCategory: nil)
    }

    /// 列表副文案：`类型 / 作者`。
    var typeAuthorLine: String? {
        let category = listCategory
        if category == .all {
            return author?.nonEmpty
        }
        let type = category.title
        if let author = author?.nonEmpty {
            return "\(type) / \(author)"
        }
        return type
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