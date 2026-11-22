import Foundation

/// 演员相关接口。
extension OneClient {
    static func actorMainNavigations() async throws -> [ActorNavigation] {
        let envelope = try await post(
            OneApiEnvelope<ActorNavigationsPayload>.self,
            path: OneAPI.actorMainNavigationsPath,
            data: nil
        )
        let list = try unwrap(envelope)?.list ?? []
        return list.sorted { ($0.sort ?? .max) < ($1.sort ?? .max) }
    }

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

    static func actorNewActors(page: Int, size: Int = 9, keyword: String = "") async throws -> ActorListPayload {
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

    static func actorHotActors(page: Int, size: Int = 9, keyword: String = "") async throws -> [ActorSummary] {
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

    /// 切换演员收藏（body：`id`）。
    static func actorCollect(actorID: Int) async throws {
        let envelope = try await post(
            OneApiEnvelope<IgnoredJSON?>.self,
            path: OneAPI.actorCollectPath,
            data: ["id": String(actorID)]
        )
        _ = try unwrap(envelope)
    }

    /// 我关注的演员（`page` / `size` / `keyword`）。
    static func actorCollectActors(
        page: Int,
        size: Int = 30,
        keyword: String = ""
    ) async throws -> [ActorSummary] {
        let envelope = try await post(
            OneApiEnvelope<ActorListPayload>.self,
            path: OneAPI.actorGetCollectActorsPath,
            data: [
                "page": String(page),
                "size": String(size),
                "keyword": keyword,
            ]
        )
        return try unwrap(envelope)?.list ?? []
    }

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

    static func actorPhotos(actorID: Int, page: Int, size: Int = 30) async throws -> [ActorPhoto] {
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
}
