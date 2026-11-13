import SwiftUI

/// 点播根页面：顶部分类胶囊切换列表（内容区不横向滑页）。
struct VodTabContent: View {
    @Bindable private var session = VodSession.shared
    @State private var selectedTagID: Int?

    var body: some View {
        NavigationStack {
            content
                .fillPage()
                .navigationDestination(for: ArticleSummary.self) { article in
                    ArticleDetailView(article: article)
                }
                .refreshable {
                    await session.refresh()
                    if let selectedTagID {
                        await session.loadArticles(for: selectedTagID, force: true)
                    }
                }
                .task { await session.loadIfNeeded() }
                .onChange(of: session.tags, initial: true) { _, tags in
                    syncSelection(with: tags)
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

    @ViewBuilder
    private var tagContent: some View {
        if let selectedTagID,
           let tag = session.tags.first(where: { $0.id == selectedTagID }) {
            TagPane(tag: tag)
                .id(selectedTagID)
        } else {
            Color.clear
        }
    }

    private func syncSelection(with tags: [DemandTag]) {
        if let selectedTagID, tags.contains(where: { $0.id == selectedTagID }) { return }
        selectedTagID = tags.first?.id
    }
}

#Preview {
    VodTabContent()
}
