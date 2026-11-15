import Foundation

/// 发现页顶部频道（对应 `article/discovery` 的 `model_id`）。
enum DiscoverChannel: Int, CaseIterable, Identifiable, Hashable {
    case graphic = 1
    case reading = 2
    case film = 3
    case radio = 5

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .graphic: "图文"
        case .reading: "阅读"
        case .film: "影视"
        case .radio: "电台"
        }
    }
}
