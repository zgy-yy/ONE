import SwiftUI

/// 列表封面比例；由调用方直接选用，不做类型推断。
enum CoverAspect {
    static let landscape: CGFloat = 16.0 / 9.0
    /// 发现图文网格常用 4:3。
    static let fourThree: CGFloat = 4.0 / 3.0
    /// 阅读列表方形封面。
    static let square: CGFloat = 1
    /// 首页图文等竖图 3:4。
    static let portrait: CGFloat = 3.0 / 4.0

    /// 由宽度与比例得到高度。
    static func height(width: CGFloat, aspect: CGFloat = landscape) -> CGFloat {
        width / aspect
    }
}

/// 封面底部叠字用的暗角渐变。
struct CoverBottomFade: View {
    var opacity: Double = 0.55

    var body: some View {
        LinearGradient(
            colors: [.clear, .black.opacity(opacity)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

extension View {
    /// 右侧信息列与封面同高，避免内容撑高后底栏落到封面下方。
    /// - Parameters:
    ///   - width: 封面宽度
    ///   - aspect: 封面宽高比（宽 / 高）
    ///   - padding: 上下内边距（先垫再定高，总高度仍等于封面高）
    func matchCoverHeight(
        width: CGFloat,
        aspect: CGFloat = CoverAspect.landscape,
        padding: CGFloat = 5
    ) -> some View {
        let height = CoverAspect.height(width: width, aspect: aspect)
        return self
            .padding(.vertical, padding)
            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height, alignment: .topLeading)
    }
}
