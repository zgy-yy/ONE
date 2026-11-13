import SwiftUI

enum OnDemandUI {
    static let pageBackground = Color.black
    static let listRowBackground = Color(white: 0.08)
    static let listRowSeparator = Color(white: 0.15)
    private static let emptyMuted = Color(white: 0.35)

    static func loading(_ message: String) -> some View {
        ProgressView(message)
            .tint(.white)
    }

    @ViewBuilder
    static func loadFailure(message: String, retry: @escaping () -> Void) -> some View {
        ContentUnavailableView {
            Label("加载失败", systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button("重试", action: retry)
        }
    }

    static func emptyState(icon: String, title: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(emptyMuted)
            Text(title)
                .font(.title3)
                .foregroundStyle(emptyMuted)
        }
    }
}

extension View {
    func onDemandPage() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(OnDemandUI.pageBackground)
    }

    func onDemandListFooterRow() -> some View {
        frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}
