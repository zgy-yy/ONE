import CoreGraphics

/// 列表封面比例常量；由调用方直接选用，不做类型推断。
enum CoverAspect {
    static let landscape: CGFloat = 16.0 / 9.0
    static let portrait: CGFloat = 3.0 / 4.0
}
