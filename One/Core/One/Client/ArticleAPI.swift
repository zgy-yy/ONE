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

    static func articleDetail(articleID: Int) async throws -> ArticleDetail {
        let envelope = try await post(
            OneApiEnvelope<ArticleDetail>.self,
            path: OneAPI.detailPath,
            data: [
                "id": String(articleID),
                "dn": ArticlePlayURL.detailVideoDN,
            ]
        )
        guard let article = try unwrap(envelope) else {
            throw OneClientError.apiRejected("详情为空")
        }
        return article
    }
}
