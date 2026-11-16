import Foundation

/// 分类 / 新晋 / 热门列表中的演员摘要。
struct ActorSummary: Decodable, Identifiable, Hashable {
    let id: Int
    let mainName: String?
    let thumb: String?
    let thumbnail: String?
    let latestPublishedAt: String?
    let score: Int?

    var displayName: String {
        mainName?.nonEmpty ?? "演员 \(id)"
    }

    var imagePath: String? {
        ImagePath.preferred(thumb: thumb, thumbnail: thumbnail)
    }

    enum CodingKeys: String, CodingKey {
        case id, thumb, thumbnail, score
        case mainName = "main_name"
        case latestPublishedAt = "latest_published_at"
    }
}

/// 演员列表 `data`（分类 / 最新 / 最热共用；最新可能带 `date`）。
struct ActorListPayload: Decodable {
    let list: [ActorSummary]?
    let date: String?

    init(list: [ActorSummary]?, date: String?) {
        self.list = list
        self.date = date
    }
}

/// 顶栏选中项：左侧固定「最新 / 最热」，或主分类。
enum ActorTabSelection: Hashable {
    case newest
    case hottest
    case navigation(Int)

    var title: String {
        switch self {
        case .newest: "最新"
        case .hottest: "最热"
        case .navigation: "分类"
        }
    }
}
