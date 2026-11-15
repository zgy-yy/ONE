import SwiftUI

/// 点播根页面：顶部分类胶囊切换列表（内容区不横向滑页）。
///
/// 各分类列表保活：切走再切回时保留滚动位置。
struct VodTabContent: View {
    @Bindable private var session = VodSession.shared
    @State private var selectedTagID: Int?
    /// 只挂载访问过的分类，避免一次创建全部 TagPane。
    @State private var visitedTagIDs: Set<Int> = []

    var body: some View {
        NavigationStack {
            content
                .fillPage()
                .navigationDestination(for: ArticleSummary.self) { article in
                    ArticleDetailView(article: article)
                }
                .task { await session.loadIfNeeded() }
                .onChange(of: session.tags, initial: true) { _, tags in
                    syncSelection(with: tags)
                }
                .onChange(of: selectedTagID) { _, newID in
                    if let newID { visitedTagIDs.insert(newID) }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if session.isLoading, session.tags.isEmpty {
            AppUI.loading("加载点播分类…")
        } else if let lastError = session.lastError, session.tags.isEmpty {
            AppUI.loadFailure(message: lastError) {
                Task { await session.refresh() }
            }
        } else if session.tags.isEmpty {
            ContentUnavailableView("暂无分类", systemImage: "tag")
        } else {
            tagContent
                .safeAreaInset(edge: .top, spacing: 0) {
                    TopBar(
                        tags: session.tags,
                        selectedTagID: $selectedTagID,
                        session: session
                    )
                }
        }
    }

    private var tagContent: some View {
        ZStack {
            ForEach(session.tags.filter { visitedTagIDs.contains($0.id) }) { tag in
                TagPane(tag: tag)
                    .opacity(tag.id == selectedTagID ? 1 : 0)
                    .allowsHitTesting(tag.id == selectedTagID)
                    .accessibilityHidden(tag.id != selectedTagID)
            }
        }
    }

    private func syncSelection(with tags: [DemandTag]) {
        if let selectedTagID, tags.contains(where: { $0.id == selectedTagID }) {
            visitedTagIDs.insert(selectedTagID)
            return
        }
        selectedTagID = tags.first?.id
        if let id = tags.first?.id {
            visitedTagIDs.insert(id)
        }
    }
}

#Preview {
    VodTabContent()
}
