import Foundation

/// 写真 / 漫画连载状态（接口 `type`）。
enum SeriesStatusType: Int, CaseIterable, Identifiable, Hashable {
    case all = 0
    case ongoing = 1
    case finished = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .all: "全部"
        case .ongoing: "连载中"
        case .finished: "已完结"
        }
    }
}

/// `series/album/list`、`series/manga/list` 列表项。
struct SeriesSummary: Decodable, Identifiable, Hashable {
    let id: Int
    let title: String?
    let author: String?
    let thumb: String?
    let thumbnail: String?
    let end: Int?
    let firstAt: String?
    let latestAt: String?
    let likeTotal: String?

    var displayTitle: String {
        title?.nonEmpty ?? "系列 \(id)"
    }

    var imagePath: String? {
        OneThumbPath.preferred(thumb: thumb, thumbnail: thumbnail)
    }

    var isFinished: Bool { end == 1 }

    var statusText: String {
        isFinished ? "已完结" : "连载中"
    }

    enum CodingKeys: String, CodingKey {
        case id, title, author, thumb, thumbnail, end
        case firstAt = "first_at"
        case latestAt = "latest_at"
        case likeTotal = "like_total"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        title = try c.decodeIfPresent(String.self, forKey: .title)
        author = try c.decodeIfPresent(String.self, forKey: .author)
        thumb = try c.decodeIfPresent(String.self, forKey: .thumb)
        thumbnail = try c.decodeIfPresent(String.self, forKey: .thumbnail)
        end = try c.decodeIfPresent(Int.self, forKey: .end)
        firstAt = try c.decodeIfPresent(String.self, forKey: .firstAt)
        latestAt = try c.decodeIfPresent(String.self, forKey: .latestAt)
        // 接口可能返回数字或字符串。
        if let text = try c.decodeIfPresent(String.self, forKey: .likeTotal) {
            likeTotal = text
        } else if let number = try c.decodeIfPresent(Int.self, forKey: .likeTotal) {
            likeTotal = String(number)
        } else {
            likeTotal = nil
        }
    }
}

/// 系列列表的 `data`：数组，或 `"0"/"1"/…` 字典。
struct SeriesListPayload: Decodable {
    let items: [SeriesSummary]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let list = try? container.decode([SeriesSummary].self) {
            items = list
            return
        }
        let dict = try container.decode([String: SeriesSummary].self)
        items = dict.keys
            .compactMap(Int.init)
            .sorted()
            .compactMap { dict[String($0)] }
    }
}
