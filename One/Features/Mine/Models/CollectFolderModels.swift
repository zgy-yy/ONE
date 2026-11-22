import Foundation

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

    var canRename: Bool { !isDefault }
    var canDelete: Bool { !isDefault }

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

/// 进入某收藏夹详情。
struct CollectFolderRoute: Hashable {
    let folderID: Int
    let folderName: String
}