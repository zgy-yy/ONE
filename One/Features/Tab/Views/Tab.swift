import SwiftUI

/// 点播 Tab 根页面：顶部分类 + 左右滑动切换列表。
///
/// - `NavigationStack`：导航栏 + 子页面栈（iOS 16+）。
/// - `@State private var selectedTagID`：当前选中的分类，驱动 `TabView` 与 `TagStrip`。
/// - `safeAreaInset(edge: .top)`：把分类条叠在内容上方，不挤占全屏列表高度。
/// - 内层 `TabView` + `.page`：与底部 Tab 无关，这里用于分类之间的横向翻页。
struct Tab: View {
    @Bindable private var session = TabSession.shared
    @State private var selectedTagID: Int?

    var body: some View {
        NavigationStack {
            Group {
                if session.isLoading, session.tags.isEmpty {
                    ProgressView("加载点播分类…")
                        .tint(.white)
                } else if let lastError = session.lastError, session.tags.isEmpty {
                    ContentUnavailableView {
                        Label("加载失败", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text(lastError)
                    } actions: {
                        Button("重试") {
                            Task { await session.refresh() }
                        }
                    }
                } else if session.tags.isEmpty {
                    ContentUnavailableView("暂无分类", systemImage: "tag")
                } else {
                    tabPages
                        .safeAreaInset(edge: .top, spacing: 0) {
                            TagStrip(tags: session.tags, selectedTagID: $selectedTagID)
                        }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .navigationTitle("点播")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await session.refresh()
                if let selectedTagID {
                    await session.loadArticles(for: selectedTagID, force: true)
                }
            }
            .task {
                await session.loadIfNeeded()
            }
            .onChange(of: session.tags) { _, tags in
                syncSelection(with: tags)
            }
            .onAppear {
                syncSelection(with: session.tags)
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var tabPages: some View {
        TabView(selection: $selectedTagID) {
            ForEach(session.tags) { tag in
                TabTagPane(tag: tag)
                    .tag(Optional(tag.id))
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    /// 分类列表刷新后，保证选中项仍有效，否则选第一项。
    private func syncSelection(with tags: [DemandTag]) {
        if let selectedTagID, tags.contains(where: { $0.id == selectedTagID }) {
            return
        }
        selectedTagID = tags.first?.id
    }
}

#Preview {
    Tab()
}
