import Foundation

/// 点播顶栏标签。
struct DemandTag: Decodable, Identifiable, Hashable {
    let id: Int
    let title: String?

    /// 「全部」：请求时 `demand_tag_id=0`。
    static let all = DemandTag(id: 0, title: "全部")

    var displayTitle: String {
        if let title, !title.isEmpty { return title }
        return "标签 \(id)"
    }
}
