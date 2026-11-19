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
    static let actorMainNavigationsPath = "actor/getMainNavigations"
    static let actorMainNavigationActorsPath = "actor/getMainNavigationActors"
    static let actorNewActorsPath = "actor/getNewActors"
    static let actorHotActorsPath = "actor/getHotActors"
    static let actorDetailPath = "actor/detail"
    static let actorArticlesPath = "actor/getActorArticles"
    static let actorPhotosPath = "actor/getActorPhotos"
    static let commentListPath = "comment/listV254"
    /// 旧版列表：展开楼中楼时用，会带回主楼下全部回复。
    static let commentListFullPath = "comment/list"
    static let seriesAlbumListPath = "series/album/list"
    static let seriesMangaListPath = "series/manga/list"
    static let seriesChaptersPath = "series/chapters"
    static let sendSMSPath = "sendsms"
    static let userLoginPath = "user/login"
    static let userLikeListPath = "my/getUserLikeList"
    static let collectFolderListPath = "my/getCollectFolderListByPage"
    static let favoritesPath = "my/favorites"
    static let myRecordCountsPath = "demand_activity/myRecordCounts"

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
