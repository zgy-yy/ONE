import CoreGraphics
import Foundation

/// 文章 `model_id` 约定（与发现频道 / 接口一致）。
///
/// 用命名常量代替魔法数字，改一处即可全局生效。
enum ArticleModelID {
    static let graphic = 1
    static let reading = 2
    static let film = 3
    static let radio = 5
}

/// 列表封面比例：图文竖图 3:4，其余横图 16:9。
enum CoverAspect {
    static let landscape: CGFloat = 16.0 / 9.0
    static let portrait: CGFloat = 3.0 / 4.0

    static func ratio(modelID: Int?, fallback: Int? = nil) -> CGFloat {
        (modelID ?? fallback) == ArticleModelID.graphic ? portrait : landscape
    }
}
