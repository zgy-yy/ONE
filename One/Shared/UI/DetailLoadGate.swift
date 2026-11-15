import SwiftUI

/// 详情页加载门禁：只有「还没有内容」时才显示 loading / 失败。
///
/// 与列表用的 `AsyncPage` 不同：详情页在内容已有时切换分段不应闪空态。
///
/// 用法：
/// ```swift
/// DetailLoadGate(
///     isLoading: session.isLoading,
///     error: session.error,
///     hasContent: session.detail != nil,
///     loadingTitle: "加载中…",
///     retry: { Task { await session.reload() } }
/// ) {
///     contentView
/// }
/// ```
struct DetailLoadGate<Content: View>: View {
    let isLoading: Bool
    let error: String?
    /// `true` 表示已有可展示的详情数据（例如 `detail != nil`）。
    let hasContent: Bool
    var loadingTitle: String = "加载中…"
    let retry: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        Group {
            if isLoading, !hasContent {
                AppUI.loading(loadingTitle)
            } else if let error, !hasContent {
                AppUI.loadFailure(message: error, retry: retry)
            } else {
                content()
            }
        }
        .fillPage()
    }
}
