import Foundation

/// ONE 业务接口路径与响应约定（纯常量，供非隔离的 `OneClient` 使用）。
nonisolated enum OneAPI {
    /// 相对 `OneTargets.bases`（拼接后为含 `v2.5` 的基址）。
    static let demandTagListPath = "navigation/getDemandTagList"
    static let discoveryPath = "article/discovery"
    static let articleSearchPath = "article/search"
    static let articleHotWordsPath = "article/getHotWords"
    static let articleDayPath = "article/day"
    static let detailPath = "article/detail"
    /// 仅用于选 token：拉播放地址时固定 `token_one`（实际请求路径仍是 `detailPath`）。
    static let detailPlayTokenPath = "article/detail#play"
    static let articleLikePath = "article/like"
    static let articleCollectPath = "article/collect"
    static let moveToCollectFolderPath = "article/moveToCollectFolder"
    static let actorMainNavigationsPath = "actor/getMainNavigations"
    static let actorMainNavigationActorsPath = "actor/getMainNavigationActors"
    static let actorNewActorsPath = "actor/getNewActors"
    static let actorHotActorsPath = "actor/getHotActors"
    static let actorDetailPath = "actor/detail"
    static let actorCollectPath = "actor/collect"
    static let actorGetCollectActorsPath = "actor/getCollectActors"
    static let actorArticlesPath = "actor/getActorArticles"
    static let actorPhotosPath = "actor/getActorPhotos"
    static let commentListPath = "comment/listV254"
    /// 楼中楼全量：`comment_id` 为主楼 ID。
    static let commentDetailWithGroupPath = "comment/detailWithGroup"
    static let seriesAlbumListPath = "series/album/list"
    static let seriesMangaListPath = "series/manga/list"
    static let seriesChaptersPath = "series/chapters"
    static let sendSMSPath = "sendsms"
    static let userLoginPath = "user/login"
    static let userLikeListPath = "my/getUserLikeList"
    static let collectFolderListPath = "my/getCollectFolderListByPage"
    static let createCollectFolderPath = "my/createCollectFolder"
    static let updateCollectFolderPath = "my/updateCollectFolder"
    static let deleteCollectFolderPath = "my/deleteCollectFolder"
    static let favoritesPath = "my/favorites"

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
