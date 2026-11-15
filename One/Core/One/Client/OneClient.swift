import Foundation

/// 业务 API 客户端：选线、签名 POST、具体接口方法。
enum OneClient {
    private static let probeTimeout: TimeInterval = 20

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

    private static let apiTimeout: TimeInterval = 30

    /// ONE 业务 POST（base 已含 `v2.5`；`data == nil` 时无 body，如 `getDemandTagList`）
    static func post<T: Decodable>(
        _ type: T.Type,
        base: URL,
        path: String,
        token: String,
        data: [String: String]? = nil
    ) async throws -> T {
        let url = APIURL.join(base: base.absoluteString, path: path)
        let headers = OneCrypto.makeRequestHeaders(token: token)
        let body = try data.map { try OneCrypto.encryptMapBody($0) }
        return try await HTTPClient.postText(
            type,
            to: url,
            body: body,
            headerFields: headers,
            timeout: apiTimeout,
            responseDecoder: HTTPResponseDecoders.one
        )
    }

    static func getDemandTagList(base: URL, token: String) async throws -> [DemandTag] {
        let envelope = try await post(
            OneApiEnvelope<[DemandTag]>.self,
            base: base,
            path: OneAPI.demandTagListPath,
            token: token,
            data: nil
        )
        return try unwrap(envelope) ?? []
    }

    static func articleDiscovery(
        base: URL,
        token: String,
        request: DiscoveryRequest
    ) async throws -> [ArticleSummary] {
        let envelope = try await post(
            OneApiEnvelope<DiscoveryListPayload>.self,
            base: base,
            path: OneAPI.discoveryPath,
            token: token,
            data: request.formBody()
        )
        return try unwrap(envelope)?.articles ?? []
    }

    static func articleDetail(base: URL, token: String, articleID: Int) async throws -> ArticleDetail {
        let envelope = try await post(
            OneApiEnvelope<ArticleDetail>.self,
            base: base,
            path: OneAPI.detailPath,
            token: token,
            data: ["id": String(articleID)]
        )
        guard let article = try unwrap(envelope) else {
            throw OneClientError.apiRejected("详情为空")
        }
        return article
    }

    /// 演员主分类（地区等）。
    static func actorMainNavigations(base: URL, token: String) async throws -> [ActorNavigation] {
        let envelope = try await post(
            OneApiEnvelope<ActorNavigationsPayload>.self,
            base: base,
            path: OneAPI.actorMainNavigationsPath,
            token: token,
            data: nil
        )
        let list = try unwrap(envelope)?.list ?? []
        return list.sorted { ($0.sort ?? .max) < ($1.sort ?? .max) }
    }

    /// 某主分类下的演员分页列表（可选 `tag_ids` 逗号分隔筛选）。
    static func actorMainNavigationActors(
        base: URL,
        token: String,
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
            base: base,
            path: OneAPI.actorMainNavigationActorsPath,
            token: token,
            data: data
        )
        return try unwrap(envelope)?.list ?? []
    }

    /// 最新演员。
    static func actorNewActors(
        base: URL,
        token: String,
        page: Int,
        size: Int = 9,
        keyword: String = ""
    ) async throws -> ActorListPayload {
        let envelope = try await post(
            OneApiEnvelope<ActorListPayload>.self,
            base: base,
            path: OneAPI.actorNewActorsPath,
            token: token,
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
        base: URL,
        token: String,
        page: Int,
        size: Int = 9,
        keyword: String = ""
    ) async throws -> [ActorSummary] {
        let envelope = try await post(
            OneApiEnvelope<ActorListPayload>.self,
            base: base,
            path: OneAPI.actorHotActorsPath,
            token: token,
            data: [
                "page": String(page),
                "size": String(size),
                "keyword": keyword,
            ]
        )
        return try unwrap(envelope)?.list ?? []
    }

    /// 演员详情。
    static func actorDetail(base: URL, token: String, actorID: Int) async throws -> ActorDetail {
        let envelope = try await post(
            OneApiEnvelope<ActorDetail>.self,
            base: base,
            path: OneAPI.actorDetailPath,
            token: token,
            data: ["id": String(actorID)]
        )
        guard let detail = try unwrap(envelope) else {
            throw OneClientError.apiRejected("演员详情为空")
        }
        return detail
    }

    /// 演员作品列表。
    static func actorArticles(
        base: URL,
        token: String,
        actorID: Int,
        page: Int,
        size: Int = 30,
        keyword: String = "",
        sort: String = "published_at"
    ) async throws -> [ArticleSummary] {
        let envelope = try await post(
            OneApiEnvelope<ActorArticlesPayload>.self,
            base: base,
            path: OneAPI.actorArticlesPath,
            token: token,
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
        base: URL,
        token: String,
        actorID: Int,
        page: Int,
        size: Int = 30
    ) async throws -> [ActorPhoto] {
        let envelope = try await post(
            OneApiEnvelope<ActorPhotosPayload>.self,
            base: base,
            path: OneAPI.actorPhotosPath,
            token: token,
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
        base: URL,
        token: String,
        type: Int,
        page: Int,
        size: Int = 20,
        sort: String = "published_at"
    ) async throws -> [SeriesSummary] {
        try await seriesList(
            path: OneAPI.seriesAlbumListPath,
            base: base,
            token: token,
            type: type,
            page: page,
            size: size,
            sort: sort
        )
    }

    /// 漫画系列列表。
    static func seriesMangaList(
        base: URL,
        token: String,
        type: Int,
        page: Int,
        size: Int = 20,
        sort: String = "published_at"
    ) async throws -> [SeriesSummary] {
        try await seriesList(
            path: OneAPI.seriesMangaListPath,
            base: base,
            token: token,
            type: type,
            page: page,
            size: size,
            sort: sort
        )
    }

    private static func seriesList(
        path: String,
        base: URL,
        token: String,
        type: Int,
        page: Int,
        size: Int,
        sort: String
    ) async throws -> [SeriesSummary] {
        let envelope = try await post(
            OneApiEnvelope<SeriesListPayload>.self,
            base: base,
            path: path,
            token: token,
            data: [
                "type": String(type),
                "page": String(page),
                "size": String(size),
                "sort": sort,
            ]
        )
        return try unwrap(envelope)?.items ?? []
    }

    /// 系列章节列表。
    static func seriesChapters(
        base: URL,
        token: String,
        seriesID: Int
    ) async throws -> SeriesDetail {
        let envelope = try await post(
            OneApiEnvelope<SeriesDetail>.self,
            base: base,
            path: OneAPI.seriesChaptersPath,
            token: token,
            data: ["series_id": String(seriesID)]
        )
        guard let detail = try unwrap(envelope) else {
            throw OneClientError.apiRejected("章节为空")
        }
        return detail
    }

    /// 评论列表（演员用 `type=2`，`article_id` 传演员 ID）。
    static func commentList(
        base: URL,
        token: String,
        targetID: Int,
        type: Int,
        page: Int,
        size: Int = 10,
        sorting: String = "likes",
        commentID: Int = 0
    ) async throws -> [CommentItem] {
        let envelope = try await post(
            OneApiEnvelope<CommentListPayload>.self,
            base: base,
            path: OneAPI.commentListPath,
            token: token,
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
