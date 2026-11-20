import SwiftUI

/// 打开搜索 sheet；带 `keyword` 时提交搜索，带 `category` 时同步顶栏分类。
struct OpenSearchRequest: Equatable {
    var keyword: String?
    var category: ContentCategory?

    static let browse = OpenSearchRequest(keyword: nil, category: nil)
}

/// 打开全局搜索（由 `MainTabView` 注入）。
private struct OpenSearchKey: EnvironmentKey {
    static let defaultValue: (OpenSearchRequest) -> Void = { _ in }
}

extension EnvironmentValues {
    var openSearch: (OpenSearchRequest) -> Void {
        get { self[OpenSearchKey.self] }
        set { self[OpenSearchKey.self] = newValue }
    }
}

/// 顶栏右侧搜索按钮（主流 iOS 布局：不与底部 Tab 争抢）。
struct SearchBarButton: View {
    @Environment(\.openSearch) private var openSearch

    var body: some View {
        Button(action: { openSearch(.browse) }) {
            Image(systemName: "magnifyingglass")
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("搜索")
    }
}

extension View {
    /// 搜索以大卡片 sheet 弹出。
    func searchCardSheet(isPresented: Binding<Bool>) -> some View {
        sheet(isPresented: isPresented) {
            SearchView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(16)
        }
    }
}
