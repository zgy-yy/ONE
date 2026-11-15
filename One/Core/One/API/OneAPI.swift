import Foundation

/// ONE 业务接口路径与响应约定。
enum OneAPI {
    /// 相对 `OneTargets.bases`（拼接后为含 `v2.5` 的基址）。
    static let demandTagListPath = "navigation/getDemandTagList"
    static let discoveryPath = "article/discovery"
    static let detailPath = "article/detail"
    static let actorMainNavigationsPath = "actor/getMainNavigations"
    static let actorMainNavigationActorsPath = "actor/getMainNavigationActors"
    static let actorNewActorsPath = "actor/getNewActors"
    static let actorHotActorsPath = "actor/getHotActors"
    static let actorDetailPath = "actor/detail"
    static let actorArticlesPath = "actor/getActorArticles"
    static let actorPhotosPath = "actor/getActorPhotos"
    static let commentListPath = "comment/listV254"
    static let seriesAlbumListPath = "series/album/list"
    static let seriesMangaListPath = "series/manga/list"
    static let seriesChaptersPath = "series/chapters"

    static func isSuccess(code: Int?) -> Bool {
        code == 200 || code == 400
    }
}

/// 通用 JSON 壳：`{ code, message, data }`。
struct OneApiEnvelope<T: Decodable>: Decodable {
    let code: Int?
    let message: String?
    let data: T?
}
