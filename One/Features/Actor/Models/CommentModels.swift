import Foundation

/// `comment/listV254` 评论项（含图片与楼中楼回复）。
struct CommentItem: Decodable, Identifiable, Hashable {
    let id: Int
    let author: String?
    let text: String?
    let createdAt: String?
    let likes: Int?
    let replyCount: Int?
    let avatar: String?
    let avatarThumbnail: String?
    /// 单图（旧字段）
    let imagePath: String?
    let imageBigPath: String?
    let imageSmallPath: String?
    /// 多图路径（接口可能是字符串数组或对象数组）
    let imagePaths: [String]
    /// 楼中楼回复
    let replies: [CommentItem]

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

    /// 评论配图：优先 `images`，否则回退单图字段。
    var displayImagePaths: [String] {
        if !imagePaths.isEmpty { return imagePaths }
        if let path = OneThumbPath.preferred(thumb: imagePath, thumbnail: imageSmallPath)
            ?? imageBigPath?.nonEmpty
        {
            return [path]
        }
        return []
    }

    enum CodingKeys: String, CodingKey {
        case id, author, text, likes, avatar, images, replies
        case createdAt = "created_at"
        case replyCount = "reply_count"
        case avatarThumbnail = "avatar_thumbnail"
        case imagePath = "image_path"
        case imageBigPath = "image_big_path"
        case imageSmallPath = "image_small_path"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        author = try c.decodeIfPresent(String.self, forKey: .author)
        text = try c.decodeIfPresent(String.self, forKey: .text)
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
        likes = JSONFlex.int(c, .likes)
        replyCount = JSONFlex.int(c, .replyCount)
        avatar = try c.decodeIfPresent(String.self, forKey: .avatar)
        avatarThumbnail = try c.decodeIfPresent(String.self, forKey: .avatarThumbnail)
        imagePath = try c.decodeIfPresent(String.self, forKey: .imagePath)
        imageBigPath = try c.decodeIfPresent(String.self, forKey: .imageBigPath)
        imageSmallPath = try c.decodeIfPresent(String.self, forKey: .imageSmallPath)
        imagePaths = Self.decodeImagePaths(c)
        replies = (try? c.decodeIfPresent([CommentItem].self, forKey: .replies)) ?? []
    }

    private static func decodeImagePaths<K: CodingKey>(_ c: KeyedDecodingContainer<K>) -> [String] {
        guard let key = K(stringValue: "images"), c.contains(key) else { return [] }

        if let strings = try? c.decode([String].self, forKey: key) {
            return strings.compactMap(\.nonEmpty)
        }
        if let objects = try? c.decode([CommentImageObject].self, forKey: key) {
            return objects.compactMap(\.preferred)
        }
        return []
    }
}

/// 评论 `images` 数组里的对象形态。
private struct CommentImageObject: Decodable {
    let path: String?
    let imagePath: String?
    let imageSmallPath: String?
    let imageBigPath: String?
    let url: String?

    enum CodingKeys: String, CodingKey {
        case path, url
        case imagePath = "image_path"
        case imageSmallPath = "image_small_path"
        case imageBigPath = "image_big_path"
    }

    var preferred: String? {
        OneThumbPath.preferred(thumb: imagePath ?? path, thumbnail: imageSmallPath)
            ?? imageBigPath?.nonEmpty
            ?? url?.nonEmpty
    }
}

/// `comment/listV254` 的 `data`。
struct CommentListPayload: Decodable {
    let list: [CommentItem]?
}
