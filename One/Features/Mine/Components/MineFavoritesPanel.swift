import SwiftUI

/// 收藏 Tab：仅展示收藏夹列表。
struct MineFavoritesPanel: View {
    @Bindable private var session = MineLibrarySession.shared

    @State private var showsCreateFolder = false

    var body: some View {
        VStack(spacing: 0) {
            createFolderBar
            CollectFolderSortBar(sort: $session.folderSort)

            Group {
                if session.isLoadingFolders, session.folders.isEmpty {
                    ProgressView("加载收藏夹…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = session.foldersError, session.folders.isEmpty {
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
                } else if session.folders.isEmpty {
                    ContentUnavailableView {
                        Label("暂无收藏夹", systemImage: "folder")
                    } actions: {
                        Button("新建收藏夹") { showsCreateFolder = true }
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
                    }
                    .plainContentList(onRefresh: { await session.loadFolders(force: true) })
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .task { await session.loadFolders() }
        .onChange(of: session.folderSort) { _, _ in
            Task { await session.loadFolders(force: true) }
        }
        .sheet(isPresented: $showsCreateFolder) {
            CreateCollectFolderSheet(session: session)
                .presentationDetents([.medium])
        }
    }

    private var createFolderBar: some View {
        HStack {
            Spacer(minLength: 0)
            Button {
                showsCreateFolder = true
            } label: {
                Label("新建收藏夹", systemImage: "folder.badge.plus")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}