import Foundation

/// 收藏夹列表排序维度（接口 `sort_dim`）。
enum CollectFolderSortDimension: String, CaseIterable, Identifiable, Hashable {
    case createTime = "create_time"
    case collectTime = "collect_time"
    case itemCount = "item_count"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .createTime: "创建时间"
        case .collectTime: "收藏时间"
        case .itemCount: "内容数量"
        }
    }
}

/// 收藏夹列表排序（`sort_dim` + `sort_desc`：`1` 倒序，`0` 正序）。
struct CollectFolderSort: Equatable {
    var dimension: CollectFolderSortDimension = .createTime
    var descending: Bool = true

    var sortDesc: Int { descending ? 1 : 0 }
}