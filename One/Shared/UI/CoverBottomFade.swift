import SwiftUI

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
