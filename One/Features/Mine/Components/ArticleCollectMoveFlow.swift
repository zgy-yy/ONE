import SwiftUI

// MARK: - 数据

/// 收藏成功后的移动流程上下文。
struct CollectFolderMoveContext: Identifiable, Hashable {
    let articleID: Int
    var id: Int { articleID }
    let seed: ArticleReactionStore.State
    let message: String
}

// MARK: - 半屏提示

/// 先提示是否移动；2 秒无操作关闭；确认后进入全屏选夹。
private struct CollectFolderMovePrompt: View {
    let context: CollectFolderMoveContext
    let onDone: () -> Void
    let onPickFolder: () -> Void

    @State private var autoDismissTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.green)

                Text(context.message)
                    .font(.body)
                    .multilineTextAlignment(.center)

                Text("是否移动到其他收藏夹？")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)

            VStack(spacing: 10) {
                Button("选择收藏夹") {
                    cancelAutoDismiss()
                    onPickFolder()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)

                Button("完成") {
                    cancelAutoDismiss()
                    onDone()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .presentationDetents([.height(300)])
        .presentationDragIndicator(.visible)
        .onAppear { scheduleAutoDismiss() }
        .onDisappear { cancelAutoDismiss() }
    }

    private func scheduleAutoDismiss() {
        cancelAutoDismiss()
        autoDismissTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            await MainActor.run { onDone() }
        }
    }

    private func cancelAutoDismiss() {
        autoDismissTask?.cancel()
        autoDismissTask = nil
    }
}

// MARK: - 全屏选夹

private struct CollectFolderMoveFullScreen: View {
    let context: CollectFolderMoveContext
    let onClose: () -> Void

    @Bindable private var library = MineLibrarySession.shared
    @Bindable private var reactions = ArticleReactionStore.shared

    @State private var errorMessage: String?
    @State private var movingFolderID: Int?

    private var articleID: Int { context.articleID }

    private var displayState: ArticleReactionStore.State {
        reactions.states[articleID] ?? context.seed
    }

    var body: some View {
        NavigationStack {
            Group {
                if library.isLoadingFolders, library.folders.isEmpty {
                    ProgressView("加载收藏夹…")
                } else if let error = library.foldersError, library.folders.isEmpty {
                    loadErrorView(error)
                } else {
                    folderList
                }
            }
            .navigationTitle("移动收藏")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { onClose() }
                        .disabled(movingFolderID != nil)
                }
            }
            .task { await library.loadFolders(force: true) }
        }
    }

    @ViewBuilder
    private var folderList: some View {
        List {
            if library.folders.isEmpty {
                ContentUnavailableView("暂无收藏夹", systemImage: "folder")
            } else {
                ForEach(library.folders) { folder in
                    Button {
                        Task { await move(to: folder) }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(Color.accentColor)
                            Text(folder.displayName)
                                .foregroundStyle(.primary)
                            Spacer(minLength: 8)
                            Text(ArticleFormat.shortCount(folder.articleNum ?? 0))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                            if movingFolderID == folder.id {
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }
                    }
                    .disabled(movingFolderID != nil)
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
        .listStyle(.insetGrouped)
    }

    private func loadErrorView(_ error: String) -> some View {
        ContentUnavailableView {
            Label("加载失败", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error)
        } actions: {
            Button("重试") {
                Task { await library.loadFolders(force: true) }
            }
        }
    }

    private func move(to folder: CollectFolder) async {
        errorMessage = nil
        movingFolderID = folder.id
        defer { movingFolderID = nil }

        do {
            try await reactions.collectToFolder(
                articleID: articleID,
                folderID: folder.id,
                seed: displayState
            )
            onClose()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - 呈现

private struct CollectFolderMovePresentation: ViewModifier {
    @Binding var context: CollectFolderMoveContext?
    var onDismiss: (() -> Void)?
    @State private var folderPickerContext: CollectFolderMoveContext?

    func body(content: Content) -> some View {
        content
            .sheet(item: $context, onDismiss: onDismiss) { item in
                CollectFolderMovePrompt(
                    context: item,
                    onDone: {
                        context = nil
                        onDismiss?()
                    },
                    onPickFolder: {
                        folderPickerContext = item
                        context = nil
                    }
                )
            }
            .fullScreenCover(item: $folderPickerContext, onDismiss: onDismiss) { item in
                CollectFolderMoveFullScreen(context: item) {
                    folderPickerContext = nil
                    onDismiss?()
                }
            }
    }
}

// MARK: - 点击收藏

/// 处理「点收藏」：未登录直接切换；已登录先入默认夹再弹移动提示。
enum ArticleCollectAction {
    @MainActor
    static func handle(
        article: ArticleSummary,
        library: MineLibrarySession = .shared,
        reactions: ArticleReactionStore = .shared
    ) async -> CollectFolderMoveContext? {
        guard AuthSession.shared.isLoggedIn else {
            await reactions.toggle(.collect, articleID: article.id, seed: .init(article))
            return nil
        }

        let seed = reactions.states[article.id] ?? .init(article)

        if reactions.displayState(for: article).hasCollected {
            await reactions.toggle(.collect, articleID: article.id, seed: seed)
            return nil
        }

        await library.loadFolders()
        do {
            try await reactions.collectToFolder(
                articleID: article.id,
                folderID: library.defaultCollectFolderID,
                seed: seed
            )
            let latest = reactions.states[article.id] ?? seed
            return CollectFolderMoveContext(
                articleID: article.id,
                seed: latest,
                message: "已收藏至「\(library.defaultCollectFolderName)」"
            )
        } catch {
            print("[ArticleCollect] default folder failed id=\(article.id): \(error.localizedDescription)")
            return nil
        }
    }
}

extension View {
    /// 挂载收藏后的移动流程（半屏提示 + 全屏选夹）。
    func articleCollectMoveFlow(
        _ context: Binding<CollectFolderMoveContext?>,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        modifier(CollectFolderMovePresentation(context: context, onDismiss: onDismiss))
    }
}