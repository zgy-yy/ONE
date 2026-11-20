import SwiftUI

/// 搜索卡片：热词 / 分类 / 结果列表。
struct SearchView: View {
    @Bindable private var session = SearchSession.shared

    var body: some View {
        NavigationStack {
            content
                .fillPage()
                .navigationTitle("搜索")
                .navigationBarTitleDisplayMode(.inline)
                .searchable(
                    text: $session.draftKeyword,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "输入关键词"
                )
                .searchPresentationToolbarBehavior(.avoidHidingContent)
                .onSubmit(of: .search, session.submit)
                .safeAreaInset(edge: .top, spacing: 0) {
                    TopCapsuleBar(
                        items: Array(ContentCategory.allCases),
                        selectedID: session.category,
                        title: \.title,
                        id: \.self,
                        onSelect: { session.category = $0 }
                    )
                }
                .libraryDetailDestinations()
                .task { await session.loadHotWordsIfNeeded() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if session.committedKeyword.isEmpty {
            SearchHotWordsSection(session: session)
        } else {
            PagedAsyncList(
                state: session.results,
                loadingTitle: "搜索中…",
                emptyIcon: "magnifyingglass",
                emptyTitle: "无结果",
                retry: { Task { await session.load(force: true) } },
                onRefresh: { await session.load(force: true) },
                loadMore: { Task { await session.loadMore() } },
                row: resultRow
            )
        }
    }

    private func resultRow(_ item: SearchHit) -> some View {
        LibraryRow(
            title: item.displayTitle,
            author: item.subtitle,
            imagePath: item.imagePath,
            coverAspectRatio: session.category.coverAspect
        )
        .libraryNavigation(
            isSeries: session.category.isSeries || item.opensAsSeries,
            article: item.asArticleSummary,
            series: item.asSeriesSummary
        )
        .styledListRow()
    }
}

/// 未搜索时的热词区。
private struct SearchHotWordsSection: View {
    @Bindable var session: SearchSession

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("热门搜索")
                    .font(.headline)

                hotWordsBody
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
    }

    @ViewBuilder
    private var hotWordsBody: some View {
        if session.isLoadingHotWords, session.hotWords.isEmpty {
            ProgressView("加载热词…")
                .frame(maxWidth: .infinity, alignment: .center)
        } else if let error = session.hotWordsError, session.hotWords.isEmpty {
            AppUI.loadFailure(message: error) {
                Task { await session.loadHotWords(force: true) }
            }
        } else if session.hotWords.isEmpty {
            Text("暂无热词")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            FlowLayout(spacing: 8, lineSpacing: 10) {
                ForEach(session.hotWords) { item in
                    Button {
                        session.search(keyword: item.word)
                    } label: {
                        CapsuleChip(title: item.word, selected: false, compact: true)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    SearchView()
}
