import CoreGraphics
import Foundation

/// 列表封面比例：图文竖图 3:4，其余横图 16:9。
enum CoverAspect {
    static let landscape: CGFloat = 16.0 / 9.0
    static let portrait: CGFloat = 3.0 / 4.0

    static func ratio(modelID: Int?, fallback: Int? = nil) -> CGFloat {
        (modelID ?? fallback) == ContentCategory.ModelID.graphic ? portrait : landscape
    }
}
