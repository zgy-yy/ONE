import SwiftUI

/// 全 App 共用的页面布局与状态占位（颜色一律用语义色，不按功能模块单独配色）。
enum AppUI {
    static func loading(_ message: String) -> some View {
        ProgressView(message)
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
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }
}

extension View {
    /// 铺满可用区域，并使用系统页面背景色。
    func fillPage() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
    }

    /// `List` 底部状态行（加载更多、没有更多了等）。
    func listFooterRow() -> some View {
        frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }

    /// 普通 `List` 数据行的背景与分隔线。
    func styledListRow() -> some View {
        listRowBackground(Color(.secondarySystemGroupedBackground))
            .listRowSeparatorTint(Color(.separator))
    }
}
