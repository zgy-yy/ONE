import SwiftUI

/// 整页加载态：loading / 失败 / 空 / 内容。
///
/// - 列表、网格等「空也是一种结果」的页面用这个。
/// - 详情页请用 `DetailLoadGate`（有内容后不要闪空态）。
/// - 滚动内容里的局部区块用 `AsyncSection`。
struct AsyncPage<Content: View>: View {
    let isLoading: Bool
    let error: String?
    let isEmpty: Bool
    var loadingTitle: String = "加载中…"
    var emptyIcon: String = "circle.slash"
    var emptyTitle: String = "无内容"
    let retry: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        Group {
            if isLoading, isEmpty {
                AppUI.loading(loadingTitle)
            } else if let error, isEmpty {
                AppUI.loadFailure(message: error, retry: retry)
            } else if isEmpty {
                AppUI.emptyState(icon: emptyIcon, title: emptyTitle)
            } else {
                content()
            }
        }
        .fillPage()
    }
}
