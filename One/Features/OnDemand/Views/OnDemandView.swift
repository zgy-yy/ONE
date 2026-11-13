import SwiftUI

/// 点播根页面：顶部分类 + 左右滑动切换列表。
struct OnDemandView: View {
    @Bindable private var session = OnDemandSession.shared
    @State private var selectedTagID: Int?

    var body: some View {
        NavigationStack {
            content
                .onDemandPage()
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
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var content: some View {
        if session.isLoading, session.tags.isEmpty {
            OnDemandUI.loading("加载点播分类…")
        } else if let lastError = session.lastError, session.tags.isEmpty {
            OnDemandUI.loadFailure(message: lastError) {
                Task { await session.refresh() }
            }
        } else if session.tags.isEmpty {
            ContentUnavailableView("暂无分类", systemImage: "tag")
        } else {
            tagPages
                .safeAreaInset(edge: .top, spacing: 0) {
                    TagStrip(tags: session.tags, selectedTagID: $selectedTagID)
                }
        }
    }

    private var tagPages: some View {
        TabView(selection: pageSelection) {
            ForEach(Array(session.tags.enumerated()), id: \.element.id) { index, tag in
                OnDemandTagPane(tag: tag)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    /// `TabView` 用连续下标；`selectedTagID` 用接口 id，避免点 A 亮 B。
    private var pageSelection: Binding<Int> {
        Binding(
            get: {
                guard let selectedTagID,
                      let index = session.tags.firstIndex(where: { $0.id == selectedTagID }) else { return 0 }
                return index
            },
            set: { index in
                guard session.tags.indices.contains(index) else { return }
                selectedTagID = session.tags[index].id
            }
        )
    }

    private func syncSelection(with tags: [DemandTag]) {
        if let selectedTagID, tags.contains(where: { $0.id == selectedTagID }) { return }
        selectedTagID = tags.first?.id
    }
}

#Preview {
    OnDemandView()
}
