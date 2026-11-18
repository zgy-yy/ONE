import SwiftUI

extension View {
    /// 右侧信息列与封面同高，避免内容撑高后底栏落到封面下方。
    func matchCoverHeight(width: CGFloat, aspect: CGFloat = CoverAspect.landscape) -> some View {
        let height = width / aspect
        return frame(maxWidth: .infinity, minHeight: height, maxHeight: height, alignment: .topLeading)
    }
}
