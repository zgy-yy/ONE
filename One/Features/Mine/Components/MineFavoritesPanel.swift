import SwiftUI

/// 收藏 Tab：排序 + 收藏夹列表（品类筛选仅在夹内详情）。
struct MineFavoritesPanel: View {
    @Bindable private var session = MineLibrarySession.shared

    @State private var showsCreateFolderAlert = false
    @State private var newFolderName = ""
    @State private var deleteError: String?
    @State private var renameError: String?
    @State private var createError: String?
    @State private var progressMessage: String?
    @State private var renamingFolderID: Int?

    var body: some View {
        VStack(spacing: 0) {
            CollectFolderSortBar(sort: $session.folderSort) {
                presentCreateFolder()
            }

            folderListBody
        }
        .background(Color(.systemGroupedBackground))
        .task { await session.loadFolders() }
        .onChange(of: session.folderSort) { _, _ in
            Task { await session.loadFolders(force: true) }
        }
        .collectFolderNameAlert(
            CollectFolderAlertCopy.createTitle,
            isPresented: $showsCreateFolderAlert,
            name: $newFolderName,
            hint: CollectFolderAlertCopy.createHint,
            confirmTitle: "创建"
        ) {
            Task { await confirmCreate() }
        }
        .collectFolderErrorAlert("删除失败", error: $deleteError)
        .collectFolderErrorAlert("重命名失败", error: $renameError)
        .collectFolderErrorAlert("创建失败", error: $createError)
        .collectFolderBusyOverlay(progressMessage)
    }

    @ViewBuilder
    private var folderListBody: some View {
        Group {
            if session.isLoadingFolders, session.folders.isEmpty {
                ProgressView("加载收藏夹…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = session.foldersError, session.folders.isEmpty {
                CollectFolderLoadFailureView(message: error) {
                    Task { await session.loadFolders(force: true) }
                }
            } else if session.folders.isEmpty {
                ContentUnavailableView {
                    Label("暂无收藏夹", systemImage: "folder")
                } actions: {
                    Button("新建收藏夹") { presentCreateFolder() }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                List(session.folders) { folder in
                    CollectFolderListRow(
                        folder: folder,
                        isRenaming: renamingFolderID == folder.id,
                        onConfirmDelete: { await confirmDelete(folderID: $0) },
                        onRename: { await confirmRename($0, name: $1) }
                    )
                    .hiddenNavigationLink(
                        value: CollectFolderRoute(
                            folderID: folder.id,
                            folderName: folder.displayName
                        )
                    )
                    .allowsHitTesting(renamingFolderID != folder.id)
                    .styledListRow()
                }
                .plainContentList(onRefresh: { await session.loadFolders(force: true) })
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func presentCreateFolder() {
        newFolderName = ""
        showsCreateFolderAlert = true
    }

    private func confirmCreate() async {
        let trimmed = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        showsCreateFolderAlert = false
        progressMessage = CollectFolderAlertCopy.creatingProgress
        defer { progressMessage = nil }

        do {
            try await session.createCollectFolder(name: trimmed)
            newFolderName = ""
        } catch {
            createError = error.localizedDescription
        }
    }

    private func confirmDelete(folderID: Int) async {
        progressMessage = CollectFolderAlertCopy.deletingProgress
        defer { progressMessage = nil }

        do {
            try await session.deleteCollectFolder(folderID: folderID)
        } catch {
            deleteError = error.localizedDescription
        }
    }

    private func confirmRename(_ folder: CollectFolder, name: String) async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != folder.displayName else { return }
        renamingFolderID = folder.id
        defer { renamingFolderID = nil }

        do {
            try await session.renameCollectFolder(folderID: folder.id, name: trimmed)
        } catch {
            renameError = error.localizedDescription
        }
    }
}