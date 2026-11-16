import Foundation

/// 业务 API 客户端：选线、签名 POST、具体接口方法。
///
/// 需要 token 的接口在内部通过 `OneCredentials` 取 base + token，Feature 不必再 `pair`。
enum OneClient {
    private static let probeTimeout: TimeInterval = 20
    private static let apiTimeout: TimeInterval = 30

    /// 依次 POST `domain/check`，选第一条可用线路，返回带 `/v2.5` 的基址。
    static func pickBaseURL() async throws -> URL {
        for host in OneTargets.hostBases {
            let url = APIURL.join(base: host, path: "domain/check")
            let (statusCode, _) = await HTTPClient.postStatusCode(from: url, timeout: probeTimeout)
            if let statusCode, statusCode < 500 {
                let root = host.hasSuffix("/") ? String(host.dropLast()) : host
                return normalizedBaseURL("\(root)/\(OneTargets.apiVersion)")
            }
        }
        throw OneClientError.noAvailableLine
    }

    private static func normalizedBaseURL(_ base: String) -> URL {
        let normalized = base.hasSuffix("/") ? base : base + "/"
        guard let url = URL(string: normalized) else {
            preconditionFailure("Invalid one base: \(base)")
        }
        return url
    }

    /// ONE 业务 POST（`data == nil` 时无 body，如 `getDemandTagList`）。
    private static func post<T: Decodable>(
        _ type: T.Type,
        path: String,
        data: [String: String]? = nil
    ) async throws -> T {
        let creds = try await MainActor.run {
            try OneCredentials.requirePair(tokenPath: path)
        }
        let url = APIURL.join(base: creds.base.absoluteString, path: path)
        // 登录 / 发短信用游客 token，此时还没有 user-key。
        let userKey = (path == OneAPI.sendSMSPath || path == OneAPI.userLoginPath)
            ? ""
            : OneAuthStore.userKeyHeader
        let headers = OneCrypto.makeRequestHeaders(token: creds.token, userKey: userKey)
        let body = try data.map { try OneCrypto.encryptMapBody($0) }
        return try await HTTPClient.post(
            type,
            to: url,
            body: body,
            headerFields: headers,
            timeout: apiTimeout,
            responseDecoder: HTTPResponseDecoders.one
        )
    }

    static func getDemandTagList() async throws -> [DemandTag] {
        let envelope = try await post(
            OneApiEnvelope<[DemandTag]>.self,
            path: OneAPI.demandTagListPath,
            data: nil
        )
        return try unwrap(envelope) ?? []
    }

    /// 发现 / 点播列表：`model_id` + `published_at` + 排序分页；点播可带 `demand_tag_id`。
    static func articleDiscovery(
        modelID: Int,
        publishedAt: String,
        sort: String,
        page: Int = 1,
        size: Int = 20,
        demandTagID: Int? = nil,
        buyType: String? = nil
    ) async throws -> [ArticleSummary] {
        var data: [String: String] = [
            "size": String(size),
            "page": String(page),
            "published_at": publishedAt == "0" ? "" : publishedAt,
            "sort": sort,
            "model_id": String(modelID),
        ]
        if let demandTagID {
            data["demand_tag_id"] = String(demandTagID)
        }
        if let buyType, !buyType.isEmpty {
            data["buy_type"] = buyType
        }
        let envelope = try await post(
            OneApiEnvelope<DiscoveryListPayload>.self,
            path: OneAPI.discoveryPath,
            data: data
        )
        return try unwrap(envelope)?.articles ?? []
    }

    /// 搜索热词（无 body）。
    static func articleHotWords() async throws -> [SearchHotWord] {
        let envelope = try await post(
            OneApiEnvelope<SearchHotWordsPayload>.self,
            path: OneAPI.articleHotWordsPath,
            data: nil
        )
        return try unwrap(envelope)?.list ?? []
    }

    /// 搜索：`keyword` + `model_id` + `series_category` 分页。
    static func articleSearch(
        keyword: String,
        modelID: Int,
        seriesCategory: Int = 0,
        page: Int,
        size: Int = 20
    ) async throws -> [SearchHit] {
        let envelope = try await post(
            OneApiEnvelope<[SearchHit]>.self,
            path: OneAPI.articleSearchPath,
            data: [
                "keyword": keyword,
                "model_id": String(modelID),
                "series_category": String(seriesCategory),
                "page": String(page),
                "size": String(size),
            ]
        )
        return try unwrap(envelope) ?? []
    }

    /// 首页每日一文：`published_at=YYYY-MM-DD`。
    static func articleDay(publishedAt: String) async throws -> ArticleDayPayload {
        let envelope = try await post(
            OneApiEnvelope<ArticleDayPayload>.self,
            path: OneAPI.articleDayPath,
            data: ["published_at": publishedAt]
        )
        guard let payload = try unwrap(envelope) else {
            throw OneClientError.apiRejected("每日内容为空")
        }
        return payload
    }

    static func articleDetail(articleID: Int) async throws -> ArticleDetail {
        let envelope = try await post(
            OneApiEnvelope<ArticleDetail>.self,
            path: OneAPI.detailPath,
            data: ["id": String(articleID)]
        )
        guard let article = try unwrap(envelope) else {
            throw OneClientError.apiRejected("详情为空")
        }
        return article
    }

    /// 演员主分类（地区等）。
    static func actorMainNavigations() async throws -> [ActorNavigation] {
        let envelope = try await post(
            OneApiEnvelope<ActorNavigationsPayload>.self,
            path: OneAPI.actorMainNavigationsPath,
            data: nil
        )
        let list = try unwrap(envelope)?.list ?? []
        return list.sorted { ($0.sort ?? .max) < ($1.sort ?? .max) }
    }

    /// 某主分类下的演员分页列表（可选 `tag_ids` 逗号分隔筛选）。
    static func actorMainNavigationActors(
        mainNavigationID: Int,
        page: Int,
        size: Int = 30,
        keyword: String = "",
        tagIDs: [Int] = []
    ) async throws -> [ActorSummary] {
        var data: [String: String] = [
            "main_navigation_id": String(mainNavigationID),
            "page": String(page),
            "size": String(size),
            "keyword": keyword,
        ]
        if !tagIDs.isEmpty {
            data["tag_ids"] = tagIDs.map(String.init).joined(separator: ",")
        }
        let envelope = try await post(
            OneApiEnvelope<ActorListPayload>.self,
            path: OneAPI.actorMainNavigationActorsPath,
            data: data
        )
        return try unwrap(envelope)?.list ?? []
    }

    /// 最新演员。
    static func actorNewActors(
        page: Int,
        size: Int = 9,
        keyword: String = ""
    ) async throws -> ActorListPayload {
        let envelope = try await post(
            OneApiEnvelope<ActorListPayload>.self,
            path: OneAPI.actorNewActorsPath,
            data: [
                "page": String(page),
                "size": String(size),
                "keyword": keyword,
            ]
        )
        return try unwrap(envelope) ?? ActorListPayload(list: [], date: nil)
    }

    /// 最热演员。
    static func actorHotActors(
        page: Int,
        size: Int = 9,
        keyword: String = ""
    ) async throws -> [ActorSummary] {
        let envelope = try await post(
            OneApiEnvelope<ActorListPayload>.self,
            path: OneAPI.actorHotActorsPath,
            data: [
                "page": String(page),
                "size": String(size),
                "keyword": keyword,
            ]
        )
        return try unwrap(envelope)?.list ?? []
    }

    /// 演员详情。
    static func actorDetail(actorID: Int) async throws -> ActorDetail {
        let envelope = try await post(
            OneApiEnvelope<ActorDetail>.self,
            path: OneAPI.actorDetailPath,
            data: ["id": String(actorID)]
        )
        guard let detail = try unwrap(envelope) else {
            throw OneClientError.apiRejected("演员详情为空")
        }
        return detail
    }

    /// 演员作品列表。
    static func actorArticles(
        actorID: Int,
        page: Int,
        size: Int = 30,
        keyword: String = "",
        sort: String = "published_at"
    ) async throws -> [ArticleSummary] {
        let envelope = try await post(
            OneApiEnvelope<ActorArticlesPayload>.self,
            path: OneAPI.actorArticlesPath,
            data: [
                "id": String(actorID),
                "page": String(page),
                "size": String(size),
                "keyword": keyword,
                "sort": sort,
            ]
        )
        return try unwrap(envelope)?.list ?? []
    }

    /// 演员写真列表。
    static func actorPhotos(
        actorID: Int,
        page: Int,
        size: Int = 30
    ) async throws -> [ActorPhoto] {
        let envelope = try await post(
            OneApiEnvelope<ActorPhotosPayload>.self,
            path: OneAPI.actorPhotosPath,
            data: [
                "id": String(actorID),
                "page": String(page),
                "size": String(size),
            ]
        )
        return try unwrap(envelope)?.list ?? []
    }

    /// 写真系列列表。
    static func seriesAlbumList(
        type: Int,
        page: Int,
        size: Int = 20,
        sort: String = "published_at"
    ) async throws -> [SeriesSummary] {
        try await seriesList(
            path: OneAPI.seriesAlbumListPath,
            type: type,
            page: page,
            size: size,
            sort: sort
        )
    }

    /// 漫画系列列表。
    static func seriesMangaList(
        type: Int,
        page: Int,
        size: Int = 20,
        sort: String = "published_at"
    ) async throws -> [SeriesSummary] {
        try await seriesList(
            path: OneAPI.seriesMangaListPath,
            type: type,
            page: page,
            size: size,
            sort: sort
        )
    }

    private static func seriesList(
        path: String,
        type: Int,
        page: Int,
        size: Int,
        sort: String
    ) async throws -> [SeriesSummary] {
        let envelope = try await post(
            OneApiEnvelope<SeriesListPayload>.self,
            path: path,
            data: [
                "type": String(type),
                "page": String(page),
                "size": String(size),
                "sort": sort,
            ]
        )
        return try unwrap(envelope)?.items ?? []
    }

    /// 发送登录短信验证码。
    static func sendSMS(mobile: String, area: String = "86") async throws {
        let envelope = try await post(
            OneApiEnvelope<IgnoredJSON?>.self,
            path: OneAPI.sendSMSPath,
            data: [
                "mobile": mobile,
                "area": area,
            ]
        )
        _ = try unwrap(envelope)
    }

    /// 手机号 + 验证码登录（`login_type=0`）。
    static func userLogin(
        mobile: String,
        code: String,
        area: String = "86",
        loginType: Int = 0
    ) async throws -> LoginPayload {
        let envelope = try await post(
            OneApiEnvelope<LoginPayload>.self,
            path: OneAPI.userLoginPath,
            data: [
                "mobile": mobile,
                "area": area,
                "code": code,
                "login_type": String(loginType),
            ]
        )
        guard let payload = try unwrap(envelope) else {
            throw OneClientError.apiRejected("登录结果为空")
        }
        return payload
    }

    /// 我喜欢的列表。
    static func userLikeList(
        modelID: Int,
        seriesCategory: Int = 0
    ) async throws -> UserLikeListPayload {
        var data = ["model_id": String(modelID)]
        if seriesCategory != 0 {
            data["series_category"] = String(seriesCategory)
        }
        let envelope = try await post(
            OneApiEnvelope<UserLikeListPayload>.self,
            path: OneAPI.userLikeListPath,
            data: data
        )
        guard let payload = try unwrap(envelope) else {
            throw OneClientError.apiRejected("喜欢列表为空")
        }
        return payload
    }

    /// 收藏夹分页列表。
    static func collectFolderList(
        page: Int = 1,
        size: Int = 20,
        keyword: String = "",
        sortDim: String = "create_time",
        sortDesc: Int = 1
    ) async throws -> [CollectFolder] {
        let envelope = try await post(
            OneApiEnvelope<[CollectFolder]>.self,
            path: OneAPI.collectFolderListPath,
            data: [
                "page": String(page),
                "size": String(size),
                "keyword": keyword,
                "sort_dim": sortDim,
                "sort_desc": String(sortDesc),
            ]
        )
        return try unwrap(envelope) ?? []
    }

    /// 收藏内容列表。
    static func favorites(
        modelID: Int,
        seriesCategory: Int = 0,
        page: Int = 1,
        size: Int = 20,
        folderID: Int = 0,
        sort: String = "collect",
        sortDesc: Int = 1,
        keyword: String = "",
        purchaseStatus: String = ""
    ) async throws -> FavoritesPayload {
        let envelope = try await post(
            OneApiEnvelope<FavoritesPayload>.self,
            path: OneAPI.favoritesPath,
            data: [
                "model_id": String(modelID),
                "series_category": String(seriesCategory),
                "page": String(page),
                "size": String(size),
                "sort": sort,
                "sort_desc": String(sortDesc),
                "purchase_status": purchaseStatus,
                "user_collect_folder_id": String(folderID),
                "keyword": keyword,
            ]
        )
        guard let payload = try unwrap(envelope) else {
            throw OneClientError.apiRejected("收藏列表为空")
        }
        return payload
    }

    /// 我的活动记录数量。
    static func myRecordCounts() async throws -> MyRecordCounts {
        let envelope = try await post(
            OneApiEnvelope<MyRecordCounts>.self,
            path: OneAPI.myRecordCountsPath,
            data: nil
        )
        guard let counts = try unwrap(envelope) else {
            throw OneClientError.apiRejected("记录为空")
        }
        return counts
    }

    /// 系列章节列表。
    static func seriesChapters(seriesID: Int) async throws -> SeriesDetail {
        let envelope = try await post(
            OneApiEnvelope<SeriesDetail>.self,
            path: OneAPI.seriesChaptersPath,
            data: ["series_id": String(seriesID)]
        )
        guard let detail = try unwrap(envelope) else {
            throw OneClientError.apiRejected("章节为空")
        }
        return detail
    }

    /// 评论列表：`type=1` 文章，`type=2` 演员；`sorting` 为 `created_at` / `likes`。
    static func commentList(
        targetID: Int,
        type: Int,
        page: Int,
        size: Int = 10,
        sorting: String = CommentSort.likes.rawValue,
        commentID: Int = 0
    ) async throws -> [CommentItem] {
        let envelope = try await post(
            OneApiEnvelope<CommentListPayload>.self,
            path: OneAPI.commentListPath,
            data: [
                "article_id": String(targetID),
                "comment_id": String(commentID),
                "page": String(page),
                "size": String(size),
                "type": String(type),
                "sorting": sorting,
            ]
        )
        return try unwrap(envelope)?.list ?? []
    }

    private static func unwrap<T>(_ envelope: OneApiEnvelope<T>) throws -> T? {
        guard OneAPI.isSuccess(code: envelope.code) else {
            let detail = envelope.message ?? "code \(envelope.code.map(String.init) ?? "nil")"
            throw OneClientError.apiRejected(detail)
        }
        return envelope.data
    }
}

enum OneClientError: LocalizedError {
    case noAvailableLine
    case apiRejected(String)
    case missingToken
    case baseNotReady

    var errorDescription: String? {
        switch self {
        case .noAvailableLine: "ONE 线路不可用"
        case .apiRejected(let message): message
        case .missingToken: "缺少 ONE token，请先完成启动拉取"
        case .baseNotReady: "ONE 线路未就绪"
        }
    }
}
