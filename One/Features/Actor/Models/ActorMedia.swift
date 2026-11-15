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

/// 详情页下方内容分段。
enum ActorDetailSegment: String, CaseIterable, Identifiable {
    case articles = "作品"
    case photos = "写真"
    case comments = "评论"

    var id: String { rawValue }
}
