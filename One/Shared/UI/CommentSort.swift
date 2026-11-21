import Foundation

/// 评论列表排序（`comment/listV254` 的 `sorting`）。
enum CommentSort: String, CaseIterable, Identifiable, Hashable {
    /// 最热（默认）
    case likes = "likes"
    /// 最新
    case createdAt = "created_at"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .createdAt: "最新"
        case .likes: "最热"
        }
    }
}

/// 评论目标类型（接口字段 `type`）。
enum CommentTargetType {
    /// 文章 / 点播详情
    static let article = 1
    /// 演员详情
    static let actor = 2
}
