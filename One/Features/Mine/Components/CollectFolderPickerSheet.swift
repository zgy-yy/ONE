import SwiftUI

/// 半屏选夹（详情收藏移动、夹内批量移动共用）。
struct CollectFolderPickerSheet: View {
    let title: String
    let cancelTitle: String
    /// 不可选中的夹（如当前所在夹）。
    var disabledFolderID: Int?
    let onSelect: (CollectFolder) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @Bindable private var library = MineLibrarySession.shared

    @State private var errorMessage: String?
    @State private var busyFolderID: Int?

    var body: some View {
        NavigationStack {
            Group {
                if library.isLoadingFolders, library.folders.isEmpty {
                    ProgressView("加载收藏夹…")
                } else if let error = library.foldersError, library.folders.isEmpty {
                    folderLoadError(error)
                } else {
                    folderList
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(cancelTitle) { dismiss() }
                        .font(.subheadline.weight(.medium))
                        .buttonStyle(.plain)
                        .disabled(busyFolderID != nil)
                }
            }
            .task { await library.loadFolders(force: true) }
        }
        .presentationDetents([.fraction(0.75), .large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private var folderList: some View {
        List {
            if library.folders.isEmpty {
                ContentUnavailableView("暂无收藏夹", systemImage: "folder")
            } else {
                ForEach(library.folders) { folder in
                    Button {
                        Task { await pick(folder) }
                    } label: {
                        CollectFolderRow(folder: folder)
                            .overlay(alignment: .trailing) {
                                trailingAccessory(for: folder)
                            }
                    }
                    .buttonStyle(.plain)
                    .disabled(busyFolderID != nil || folder.id == disabledFolderID)
                    .styledListRow()
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
        .plainContentList()
    }

    @ViewBuilder
    private func trailingAccessory(for folder: CollectFolder) -> some View {
        if busyFolderID == folder.id {
            ProgressView()
                .controlSize(.regular)
                .padding(.trailing, 4)
        } else if folder.id == disabledFolderID {
            Text("当前")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.trailing, 4)
        }
    }

    private func folderLoadError(_ message: String) -> some View {
        ContentUnavailableView {
            Label("加载失败", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("重试") {
                Task { await library.loadFolders(force: true) }
            }
        }
    }

    private func pick(_ folder: CollectFolder) async {
        errorMessage = nil
        busyFolderID = folder.id
        defer { busyFolderID = nil }

        do {
            try await onSelect(folder)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}