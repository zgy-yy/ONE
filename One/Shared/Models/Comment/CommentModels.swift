import Foundation

/// 评论模型（文章 / 演员详情共用）。
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
    /// 多图路径（列表缩略，接口可能是字符串数组或对象数组）
    let imagePaths: [String]
    /// 多图原图路径（与 `imagePaths` 一一对应；字符串数组时与缩略相同）
    let fullImagePaths: [String]
    /// 楼中楼回复（`listV254` 内嵌预览，最多约 3 条）
    let replies: [CommentItem]

    var displayAuthor: String {
        if let author, !author.isEmpty { return author }
        return "用户"
    }

    var displayText: String {
        text?.nonEmpty ?? ""
    }

    var avatarPath: String? {
        ImagePath.preferred(thumb: avatar, thumbnail: avatarThumbnail)
    }

    /// 评论配图（网格缩略）：优先 `images`，否则回退单图字段。
    var displayImagePaths: [String] {
        if !imagePaths.isEmpty { return imagePaths }
        if let path = ImagePath.preferred(thumb: imagePath, thumbnail: imageSmallPath)
            ?? imageBigPath?.nonEmpty
        {
            return [path]
        }
        return []
    }

    /// 全屏浏览用原图：优先 `images` 大图，否则回退单图大图字段。
    var viewerImagePaths: [String] {
        if !fullImagePaths.isEmpty { return fullImagePaths }
        if let path = ImagePath.full(thumb: imagePath, thumbnail: imageSmallPath)
            ?? imageBigPath?.nonEmpty
            ?? imagePath?.nonEmpty
        {
            return [path]
        }
        return displayImagePaths
    }

    var replyTotal: Int { max(replyCount ?? 0, replies.count) }

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
        let decoded = Self.decodeImagePaths(c)
        imagePaths = decoded.preferred
        fullImagePaths = decoded.full
        replies = Self.decodeReplyList(c)
    }

    /// 逐条解析楼中楼，避免单条脏数据导致整段 `replies` 变空。
    private static func decodeReplyList(
        _ c: KeyedDecodingContainer<CodingKeys>
    ) -> [CommentItem] {
        guard c.contains(.replies), var unkeyed = try? c.nestedUnkeyedContainer(forKey: .replies) else {
            return []
        }
        var items: [CommentItem] = []
        while !unkeyed.isAtEnd {
            if let item = try? unkeyed.decode(CommentItem.self) {
                items.append(item)
            } else {
                _ = try? unkeyed.decode(IgnoredJSON.self)
            }
        }
        return items
    }

    private static func decodeImagePaths<K: CodingKey>(
        _ c: KeyedDecodingContainer<K>
    ) -> (preferred: [String], full: [String]) {
        guard let key = K(stringValue: "images"), c.contains(key) else {
            return ([], [])
        }

        if let strings = try? c.decode([String].self, forKey: key) {
            let paths = strings.compactMap(\.nonEmpty)
            return (paths, paths)
        }
        if let objects = try? c.decode([CommentImageObject].self, forKey: key) {
            let preferred = objects.compactMap(\.preferred)
            let full = objects.map { $0.full ?? $0.preferred }.compactMap { $0 }
            return (preferred, full.isEmpty ? preferred : full)
        }
        return ([], [])
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
        ImagePath.preferred(thumb: imagePath ?? path, thumbnail: imageSmallPath)
            ?? imageBigPath?.nonEmpty
            ?? url?.nonEmpty
    }

    var full: String? {
        ImagePath.full(thumb: imagePath ?? path, thumbnail: imageSmallPath)
            ?? imageBigPath?.nonEmpty
            ?? url?.nonEmpty
            ?? preferred
    }
}

/// 评论列表 `data`：`{ list }` 或直接为数组。
struct CommentListPayload: Decodable {
    let list: [CommentItem]?

    init(from decoder: Decoder) throws {
        if var unkeyed = try? decoder.unkeyedContainer() {
            list = Self.decodeLenientList(&unkeyed)
            return
        }
        let keyed = try decoder.container(keyedBy: CodingKeys.self)
        if var listContainer = try? keyed.nestedUnkeyedContainer(forKey: .list) {
            list = Self.decodeLenientList(&listContainer)
        } else {
            list = nil
        }
    }

    private static func decodeLenientList(_ unkeyed: inout UnkeyedDecodingContainer) -> [CommentItem] {
        var items: [CommentItem] = []
        while !unkeyed.isAtEnd {
            if let item = try? unkeyed.decode(CommentItem.self) {
                items.append(item)
            } else {
                _ = try? unkeyed.decode(IgnoredJSON.self)
            }
        }
        return items
    }

    private enum CodingKeys: String, CodingKey { case list }
}

extension [CommentItem] {
    func sorted(by sort: CommentSort) -> [CommentItem] {
        switch sort {
        case .likes:
            sorted { ($0.likes ?? 0) > ($1.likes ?? 0) }
        case .createdAt:
            sorted { ($0.createdAt ?? "") > ($1.createdAt ?? "") }
        }
    }
}
