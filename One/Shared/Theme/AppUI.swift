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

    /// 分区空态（嵌入滚动内容中，不用整页占位）。
    static func inlineEmpty(_ title: String) -> some View {
        Text(title)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
    }

    /// 列表 / 网格底部分页状态。
    ///
    /// 已加载内容末尾：加载更多时出转圈，否则出「我是有底线的」。
    /// `exhausted` 保留参数兼容旧调用，展示不再依赖它（按月列表很难到达 earliest）。
    @ViewBuilder
    static func loadMoreFooter(loadingMore: Bool, exhausted _: Bool) -> some View {
        if loadingMore {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        } else {
            Text("我是有底线的")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
    }

    /// `List` 底部的分页状态行。
    @ViewBuilder
    static func listLoadMoreFooter(loadingMore: Bool, exhausted: Bool) -> some View {
        loadMoreFooter(loadingMore: loadingMore, exhausted: exhausted)
            .listFooterRow()
    }
}

extension String {
    /// 去空白后非空则返回自身，否则 `nil`。
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
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

    /// 普通 `List` 数据行：无分隔线、无行背景、行距收紧。
    func styledListRow() -> some View {
        listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    }

    /// 内容列表通用样式（无分组、隐藏系统滚动背景）。
    func plainContentList() -> some View {
        listStyle(.plain)
            .scrollContentBackground(.hidden)
            .listSectionSpacing(8)
    }

    /// `plainContentList` + 下拉刷新。
    func plainContentList(onRefresh: @escaping @Sendable () async -> Void) -> some View {
        plainContentList()
            .refreshable(action: onRefresh)
    }

    /// 整行可点、无右侧箭头的 `NavigationLink`（适合自定义列表行）。
    ///
    /// `NavigationLink` 藏在 background，List 不会画系统 disclosure 箭头。
    /// 行内交互请用 `onTapGesture`，不要用 `Button`（会抢走跳转手势）。
    func hiddenNavigationLink<Value: Hashable>(value: Value) -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .background {
                NavigationLink(value: value) { EmptyView() }
                    .opacity(0)
            }
    }
}
