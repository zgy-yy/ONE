import Foundation

/// `actor/detail` 完整资料。
struct ActorDetail: Decodable, Identifiable {
    let id: Int
    let mainName: String?
    let japaneseName: String?
    let aliasName: String?
    let nickname: String?
    let thumb: String?
    let thumbnail: String?
    let height: String?
    let bustWaistHip: String?
    let cupSize: String?
    let birthDate: String?
    let desc: String?
    let age: String?
    let articleNum: Int?
    let photoNum: Int?
    let commentNum: Int?
    let isCollected: Int?

    var displayName: String {
        mainName?.nonEmpty ?? "演员 \(id)"
    }

    /// 列表等场景：优先小图。
    var imagePath: String? {
        OneThumbPath.preferred(thumb: thumb, thumbnail: thumbnail)
    }

    /// 详情封面：优先原图 `thumb`，更清晰。
    var coverImagePath: String? {
        OneThumbPath.full(thumb: thumb, thumbnail: thumbnail)
    }

    var displayDesc: String? {
        desc?
            .replacingOccurrences(of: "\r\n", with: "\n")
            .nonEmpty
    }

    enum CodingKeys: String, CodingKey {
        case id, thumb, thumbnail, height, nickname, desc, age
        case mainName = "main_name"
        case japaneseName = "japanese_name"
        case aliasName = "alias_name"
        case bustWaistHip = "bust_waist_hip"
        case cupSize = "cup_size"
        case birthDate = "birth_date"
        case articleNum = "article_num"
        case photoNum = "photo_num"
        case commentNum = "comment_num"
        case isCollected = "is_collected"
    }
}
