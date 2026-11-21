import Foundation

/// 文章相关接口（发现 / 搜索 / 日更 / 详情）。
extension OneClient {
    static func getDemandTagList() async throws -> [DemandTag] {
        let envelope = try await post(OneApiEnvelope<[DemandTag]>.self, path: OneAPI.demandTagListPath, data: nil)
        return try unwrap(envelope) ?? []
    }

    /// 发现 / 点播列表。
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
        if let demandTagID { data["demand_tag_id"] = String(demandTagID) }
        if let buyType, !buyType.isEmpty { data["buy_type"] = buyType }
        let envelope = try await post(OneApiEnvelope<DiscoveryListPayload>.self, path: OneAPI.discoveryPath, data: data)
        return try unwrap(envelope)?.articles ?? []
    }

    static func articleHotWords() async throws -> [SearchHotWord] {
        let envelope = try await post(OneApiEnvelope<SearchHotWordsPayload>.self, path: OneAPI.articleHotWordsPath, data: nil)
        return try unwrap(envelope)?.list ?? []
    }

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

    /// 业务详情：与其它接口相同，使用用户 / 游客 token（含 `is_like` / `is_collected`）。
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

    /// 播放地址详情：固定 `token_one`，并带 `dn`。
    static func articleDetailForPlay(articleID: Int) async throws -> ArticleDetail {
        let envelope = try await post(
            OneApiEnvelope<ArticleDetail>.self,
            path: OneAPI.detailPath,
            tokenPath: OneAPI.detailPlayTokenPath,
            data: [
                "id": String(articleID),
                "dn": ArticlePlayURL.detailVideoDN,
            ]
        )
        guard let article = try unwrap(envelope) else {
            throw OneClientError.apiRejected("播放详情为空")
        }
        return article
    }

    /// 切换喜欢（body：`id`）。
    static func articleLike(articleID: Int) async throws {
        let envelope = try await post(
            OneApiEnvelope<IgnoredJSON?>.self,
            path: OneAPI.articleLikePath,
            data: ["id": String(articleID)]
        )
        _ = try unwrap(envelope)
    }

    /// 切换收藏（body：`id`）。
    static func articleCollect(articleID: Int) async throws {
        let envelope = try await post(
            OneApiEnvelope<IgnoredJSON?>.self,
            path: OneAPI.articleCollectPath,
            data: ["id": String(articleID)]
        )
        _ = try unwrap(envelope)
    }

    /// 移动文章到收藏夹（`ids` / `item_ids` 与官网一致，逗号分隔）。
    static func moveToCollectFolder(articleIDs: [Int], folderID: Int) async throws {
        let joined = articleIDs.map(String.init).joined(separator: ",")
        let envelope = try await post(
            OneApiEnvelope<IgnoredJSON?>.self,
            path: OneAPI.moveToCollectFolderPath,
            data: [
                "ids": joined,
                "item_ids": joined,
                "user_collect_folder_id": String(folderID),
            ]
        )
        _ = try unwrap(envelope)
    }
}
