import Foundation

/// 列表排序（接口字段 `sort`）。
///
/// `CaseIterable` 的声明顺序决定 `ArticleSortPicker` 从左到右的选项：
/// 先「发布时间」，再「最受欢迎」。
enum ArticleSort: String, CaseIterable, Identifiable, Hashable {
    case publishedAt = "published_at"
    case likeNumber = "like_number"

    var id: String { rawValue }

    /// 分段控件上显示的中文标题。
    var title: String {
        switch self {
        case .publishedAt: "发布时间"
        case .likeNumber: "最受欢迎"
        }
    }
}
