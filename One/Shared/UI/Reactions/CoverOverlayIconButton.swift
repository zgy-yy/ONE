import SwiftUI

/// 叠在封面一角的可点图标（无衬底；加载中显示 `ProgressView`）。
struct CoverOverlayIconButton: View {
    let systemImage: String
    var active = false
    var isLoading = false
    var activeColor: Color = .orange
    var inactiveColor: Color = .white
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(inactiveColor)
                } else {
                    Image(systemName: systemImage)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(active ? activeColor : inactiveColor)
                        .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)
                }
            }
            .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .padding(6)
    }
}