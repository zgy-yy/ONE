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

/// 先提示是否移动；2 秒无操作关闭；确认后进入半屏选夹。
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

            Button("选择收藏夹") {
                cancelAutoDismiss()
                onPickFolder()
            }
            .font(.subheadline.weight(.medium))
            .buttonStyle(.bordered)
            .controlSize(.small)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .presentationDetents([.height(240)])
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
            .sheet(item: $folderPickerContext, onDismiss: onDismiss) { item in
                CollectFolderMovePickerSheet(context: item)
            }
    }
}

/// 收藏后：单条移入其它夹。
private struct CollectFolderMovePickerSheet: View {
    let context: CollectFolderMoveContext

    @Bindable private var reactions = ArticleReactionStore.shared

    private var articleID: Int { context.articleID }

    private var displayState: ArticleReactionStore.State {
        reactions.states[articleID] ?? context.seed
    }

    var body: some View {
        CollectFolderPickerSheet(
            title: "移动收藏",
            cancelTitle: "完成"
        ) { folder in
            try await reactions.collectToFolder(
                articleID: articleID,
                folderID: folder.id,
                seed: displayState
            )
        }
    }
}

// MARK: - 点击收藏

/// 处理「点收藏」：未登录直接切换；已登录先入默认夹再弹移动提示。
@MainActor
enum ArticleCollectAction {
    static func handle(article: ArticleSummary) async -> CollectFolderMoveContext? {
        let library = MineLibrarySession.shared
        let reactions = ArticleReactionStore.shared

        guard AuthSession.shared.isLoggedIn else {
            await reactions.toggle(.collect, articleID: article.id, seed: .init(article))
            return nil
        }

        let seed = reactions.states[article.id] ?? .init(article)

        if reactions.displayState(for: article).hasCollected {
            await reactions.toggle(.collect, articleID: article.id, seed: seed)
            return nil
        }

        reactions.markBusy(articleID: article.id, kind: .collect, busy: true)
        defer { reactions.markBusy(articleID: article.id, kind: .collect, busy: false) }

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

    /// 详情页点收藏：无移夹弹窗时刷新详情里的互动数字；返回值赋给移夹 Sheet 状态。
    @discardableResult
    static func handleInDetail(
        article: ArticleSummary,
        syncDetail: () -> Void
    ) async -> CollectFolderMoveContext? {
        let context = await handle(article: article)
        if context == nil {
            syncDetail()
        }
        return context
    }
}

extension View {
    /// 挂载收藏后的移动流程（半屏提示 + 半屏选夹）。
    func articleCollectMoveFlow(
        _ context: Binding<CollectFolderMoveContext?>,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        modifier(CollectFolderMovePresentation(context: context, onDismiss: onDismiss))
    }
}