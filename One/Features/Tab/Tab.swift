import SwiftUI

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
