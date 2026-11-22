import SwiftUI

/// 收藏夹列表行：滑动 / 长按 → 重命名（Alert）、删除（本行确认框）。
struct CollectFolderListRow: View {
    let folder: CollectFolder
    var isRenaming = false
    let onConfirmDelete: (Int) async -> Void
    let onRename: (CollectFolder, String) async -> Void

    @State private var showsDeleteConfirm = false
    @State private var showsRenameAlert = false
    @State private var renameDraft = ""

    var body: some View {
        CollectFolderRow(folder: folder)
            .overlay(alignment: .trailing) {
                if isRenaming {
                    ProgressView()
                        .controlSize(.regular)
                        .padding(.trailing, 4)
                }
            }
            .opacity(isRenaming ? 0.72 : 1)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                if folder.canDelete {
                    Button {
                        showsDeleteConfirm = true
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                    .tint(.red)
                }
                if folder.canRename {
                    Button(action: presentRename) {
                        Label("重命名", systemImage: "pencil")
                    }
                    .tint(.accentColor)
                }
            }
            .contextMenu {
                if folder.canRename {
                    Button(action: presentRename) {
                        Label("重命名", systemImage: "pencil")
                    }
                }
                if folder.canDelete {
                    Button {
                        showsDeleteConfirm = true
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
            }
            .collectFolderDeleteConfirmation(
                folderName: folder.displayName,
                isPresented: $showsDeleteConfirm
            ) {
                let folderID = folder.id
                Task { await onConfirmDelete(folderID) }
            }
            .collectFolderNameAlert(
                "重命名「\(folder.displayName)」",
                isPresented: $showsRenameAlert,
                name: $renameDraft,
                hint: CollectFolderAlertCopy.renameHint,
                confirmTitle: "保存"
            ) {
                let draft = renameDraft
                showsRenameAlert = false
                Task { await onRename(folder, draft) }
            }
            .disabled(isRenaming)
    }

    private func presentRename() {
        renameDraft = folder.displayName
        showsRenameAlert = true
    }
}