import Foundation

/// `article/discovery` 列表接口的 POST 表单字段（见各属性注释）。
struct DiscoveryRequest: Sendable {
    /// 时间筛选：`YYYY-MM`、Unix 秒，或 `0` 视为空。
    var publishedAt: String

    /// 内容模型。
    var modelID: String

    /// 点播分类 ID（`demand_tag_id`）。
    var demandTagID: Int?

    /// 每页条数。
    var size: Int

    /// 页码，从 `1` 开始。
    var page: Int

    /// 排序字段。
    var sort: String

    /// 付费类型筛选，不传则不带该字段。
    var buyType: String?

    /// 点播列表请求（`publishedAt` 为 `YYYY-MM`；`sort` 如 `like_number` / `published_at`）。
    static func vodList(
        demandTagID: Int,
        publishedAt: String,
        sort: String,
        page: Int = 1,
        size: Int = 20
    ) -> DiscoveryRequest {
        DiscoveryRequest(
            publishedAt: publishedAt,
            modelID: "6",
            demandTagID: demandTagID,
            size: size,
            page: page,
            sort: sort,
            buyType: nil
        )
    }

    /// 加密 POST 使用的 `key=value` 表单。
    func formBody() -> [String: String] {
        var body: [String: String] = [
            "size": String(size),
            "page": String(page),
            "published_at": normalizePublishedAt(publishedAt),
            "sort": sort,
            "model_id": modelID,
        ]
        if let demandTagID {
            body["demand_tag_id"] = String(demandTagID)
        }
        if let buyType, !buyType.isEmpty {
            body["buy_type"] = buyType
        }
        return body
    }

    private func normalizePublishedAt(_ value: String) -> String {
        if value == "0" { return "" }
        return value
    }
}
