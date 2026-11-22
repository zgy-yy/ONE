import SwiftUI

/// 收藏 Tab：排序 + 收藏夹列表（品类筛选仅在夹内详情）。
struct MineFavoritesPanel: View {
    @Bindable private var session = MineLibrarySession.shared

    @State private var showsCreateFolder = false
    @State private var folderToRename: CollectFolder?
    @State private var folderPendingDelete: CollectFolder?
    @State private var deleteError: String?

    var body: some View {
        VStack(spacing: 0) {
            CollectFolderSortBar(sort: $session.folderSort) {
                showsCreateFolder = true
            }

            folderListBody
        }
        .background(Color(.systemGroupedBackground))
        .task { await session.loadFolders() }
        .onChange(of: session.folderSort) { _, _ in
            Task { await session.loadFolders(force: true) }
        }
        .sheet(isPresented: $showsCreateFolder) {
            CollectFolderNameSheet(mode: .create, session: session)
                .presentationDetents([.medium])
        }
        .sheet(item: $folderToRename) { folder in
            CollectFolderNameSheet(mode: .rename(folder), session: session)
                .presentationDetents([.medium])
        }
        .confirmationDialog(
            "删除收藏夹？",
            item: $folderPendingDelete,
            titleVisibility: .visible
        ) { folder in
            Button("删除「\(folder.displayName)」", role: .destructive) {
                Task { await confirmDelete(folder) }
            }
        } message: { _ in
            Text("夹内收藏将一并移除，此操作不可撤销。")
        }
        .alert("删除失败", isPresented: .init(
            get: { deleteError != nil },
            set: { if !$0 { deleteError = nil } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            if let deleteError { Text(deleteError) }
        }
    }

    @ViewBuilder
    private var folderListBody: some View {
        Group {
            if session.isLoadingFolders, session.folders.isEmpty {
                ProgressView("加载收藏夹…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = session.foldersError, session.folders.isEmpty {
                emptyErrorView(error)
            } else if session.folders.isEmpty {
                ContentUnavailableView {
                    Label("暂无收藏夹", systemImage: "folder")
                } actions: {
                    Button("新建收藏夹") { showsCreateFolder = true }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                List(session.folders) { folder in
                    CollectFolderRow(folder: folder)
                        .hiddenNavigationLink(
                            value: CollectFolderRoute(
                                folderID: folder.id,
                                folderName: folder.displayName
                            )
                        )
                        .styledListRow()
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if folder.canDelete {
                                Button(role: .destructive) {
                                    folderPendingDelete = folder
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                            if folder.canRename {
                                Button {
                                    folderToRename = folder
                                } label: {
                                    Label("重命名", systemImage: "pencil")
                                }
                                .tint(.accentColor)
                            }
                        }
                        .contextMenu {
                            if folder.canRename {
                                Button {
                                    folderToRename = folder
                                } label: {
                                    Label("重命名", systemImage: "pencil")
                                }
                            }
                            if folder.canDelete {
                                Button(role: .destructive) {
                                    folderPendingDelete = folder
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                }
                .plainContentList(onRefresh: { await session.loadFolders(force: true) })
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func emptyErrorView(_ error: String) -> some View {
        VStack(spacing: 12) {
            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("重试") {
                Task { await session.loadFolders(force: true) }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func confirmDelete(_ folder: CollectFolder) async {
        folderPendingDelete = nil
        do {
            try await session.deleteCollectFolder(folderID: folder.id)
        } catch {
            deleteError = error.localizedDescription
        }
    }
}