import SwiftUI

/// 分区加载态：loading / 失败 / 空 / 内容。
struct AsyncSection<Content: View>: View {
    let isLoading: Bool
    let error: String?
    let isEmpty: Bool
    let loadingTitle: String
    let emptyTitle: String
    let retry: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        if isLoading, isEmpty {
            ProgressView(loadingTitle)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
        } else if let error, isEmpty {
            AppUI.loadFailure(message: error, retry: retry)
                .frame(minHeight: 160)
        } else if isEmpty {
            AppUI.inlineEmpty(emptyTitle)
        } else {
            content()
        }
    }
}
