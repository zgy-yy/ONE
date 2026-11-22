import SwiftUI

/// 单个收藏夹内的收藏内容（双列网格）。
struct CollectFolderDetailView: View {
    let route: CollectFolderRoute

    @Bindable private var session = MineLibrarySession.shared

    @State private var isManaging = false
    @State private var selectedIDs: Set<Int> = []
    @State private var showsBatchMove = false

    var body: some View {
        VStack(spacing: 0) {
            MineCategoryStrip(category: $session.favoriteCategory)
            FavoriteFolderPagedGrid(
                state: session.favorites,
                loadingTitle: "加载收藏…",
                emptyTitle: "暂无收藏",
                retry: { Task { await session.loadFavorites(force: true) } },
                onRefresh: { await session.loadFavorites(force: true) },
                loadMore: { Task { await session.loadMoreFavorites() } },
                cell: favoriteCell
            )
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(route.folderName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if isManaging {
                    Button(selectAllTitle) { toggleSelectAll() }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(isManaging ? "完成" : "管理") {
                    if isManaging {
                        endManaging()
                    } else {
                        isManaging = true
                    }
                }
                .disabled(!isManaging && session.favorites.isEmpty)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if isManaging, !selectedIDs.isEmpty {
                batchMoveBar
            }
        }
        .sheet(isPresented: $showsBatchMove) {
            CollectFolderBatchMoveSheet(
                articleIDs: Array(selectedIDs),
                currentFolderID: route.folderID,
                onSuccess: { endManaging() }
            )
        }
        .task(id: route.folderID) {
            endManaging()
            session.enterFolder(id: route.folderID)
            await session.loadFavorites()
        }
        .onChange(of: session.favoriteCategory) { _, _ in
            Task {
                endManaging()
                await session.loadFavorites(force: true)
            }
        }
    }

    private var selectAllTitle: String {
        let loaded = session.favorites.items.map(\.id)
        let allSelected = !loaded.isEmpty && loaded.allSatisfy { selectedIDs.contains($0) }
        return allSelected ? "取消全选" : "全选"
    }

    private var batchMoveBar: some View {
        Button {
            showsBatchMove = true
        } label: {
            Text("移动到收藏夹（\(selectedIDs.count)）")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    @ViewBuilder
    private func favoriteCell(_ item: FavoriteItem) -> some View {
        let isSelected = selectedIDs.contains(item.id)
        let row = FavoriteItemRow(item: item)
            .allowsHitTesting(!isManaging)
            .overlay(alignment: .topTrailing) {
                if isManaging {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(isSelected ? Color.accentColor : .white, isSelected ? Color.white : .clear)
                        .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)
                        .padding(8)
                }
            }
            .overlay {
                if isManaging, isSelected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.accentColor, lineWidth: 2)
                }
            }

        if isManaging {
            Button {
                toggleSelection(item.id)
            } label: {
                row
            }
            .buttonStyle(.plain)
        } else {
            libraryNavigationLink(
                isSeries: item.isSeries,
                article: item.asArticleSummary,
                series: item.asSeriesSummary
            ) {
                row
            }
            .buttonStyle(.plain)
        }
    }

    private func toggleSelection(_ id: Int) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    private func toggleSelectAll() {
        let loaded = session.favorites.items.map(\.id)
        guard !loaded.isEmpty else { return }
        if loaded.allSatisfy({ selectedIDs.contains($0) }) {
            selectedIDs.subtract(loaded)
        } else {
            selectedIDs.formUnion(loaded)
        }
    }

    private func endManaging() {
        isManaging = false
        selectedIDs = []
        showsBatchMove = false
    }
}