import Foundation

/// `actor/getActorArticles` 的 `data`。
struct ActorArticlesPayload: Decodable {
    let list: [ArticleSummary]?
}

/// 演员写真。
struct ActorPhoto: Decodable, Identifiable, Hashable {
    let id: Int
    let thumb: String?
    let thumbnail: String?
    let sort: Int?

    var imagePath: String? {
        OneThumbPath.preferred(thumb: thumb, thumbnail: thumbnail)
    }
}

/// `actor/getActorPhotos` 的 `data`。
struct ActorPhotosPayload: Decodable {
    let list: [ActorPhoto]?
}

/// `comment/listV254` 评论项。
struct CommentItem: Decodable, Identifiable, Hashable {
    let id: Int
    let author: String?
    let text: String?
    let createdAt: String?
    let likes: Int?
    let replyCount: Int?
    let avatar: String?
    let avatarThumbnail: String?

    var displayAuthor: String {
        if let author, !author.isEmpty { return author }
        return "用户"
    }

    var displayText: String {
        text?.nonEmpty ?? ""
    }

    var avatarPath: String? {
        OneThumbPath.preferred(thumb: avatar, thumbnail: avatarThumbnail)
    }

    enum CodingKeys: String, CodingKey {
        case id, author, text, likes, avatar
        case createdAt = "created_at"
        case replyCount = "reply_count"
        case avatarThumbnail = "avatar_thumbnail"
    }
}

/// `comment/listV254` 的 `data`。
struct CommentListPayload: Decodable {
    let list: [CommentItem]?
}

/// 详情页下方内容分段。
enum ActorDetailSegment: String, CaseIterable, Identifiable {
    case articles = "作品"
    case photos = "写真"
    case comments = "评论"

    var id: String { rawValue }
}
