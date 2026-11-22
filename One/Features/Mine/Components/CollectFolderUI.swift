import SwiftUI

// MARK: - 收藏夹弹窗（新建 / 重命名共用）

enum CollectFolderAlertCopy {
    static let createTitle = "新建收藏夹"
    static let createHint = "输入名称后点创建"
    static let renameHint = "输入新名称后点保存"
    static let fieldPlaceholder = "收藏夹名称"
}

extension View {
    /// 操作失败：`errorMessage` 非空时弹出「好」。
    func collectFolderErrorAlert(_ title: String, error: Binding<String?>) -> some View {
        alert(title, isPresented: Binding(
            get: { error.wrappedValue != nil },
            set: { if !$0 { error.wrappedValue = nil } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            if let message = error.wrappedValue {
                Text(message)
            }
        }
    }

    /// 系统 Alert + 单行输入（收藏 Tab / 选夹半屏 新建、列表行重命名共用）。
    func collectFolderNameAlert(
        _ title: String,
        isPresented: Binding<Bool>,
        name: Binding<String>,
        hint: String,
        confirmTitle: String,
        onConfirm: @escaping () -> Void
    ) -> some View {
        alert(title, isPresented: isPresented) {
            TextField(CollectFolderAlertCopy.fieldPlaceholder, text: name)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button(confirmTitle, action: onConfirm)
            Button("取消", role: .cancel) {
                name.wrappedValue = ""
            }
        } message: {
            Text(hint)
        }
    }

    /// 挂在本行上，确认框锚在所点收藏夹；先关弹窗再 `onDelete`（避免列表刷新时崩溃）。
    func collectFolderDeleteConfirmation(
        folderName: String,
        isPresented: Binding<Bool>,
        onDelete: @escaping () -> Void
    ) -> some View {
        confirmationDialog(
            "删除「\(folderName)」？",
            isPresented: isPresented,
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive) {
                isPresented.wrappedValue = false
                Task { @MainActor in
                    await Task.yield()
                    onDelete()
                }
            }
            Button("取消", role: .cancel) {
                isPresented.wrappedValue = false
            }
        } message: {
            Text("夹内收藏将一并移除，此操作不可撤销。")
        }
    }
}

// MARK: - 半屏选夹导航栏小按钮

/// 加载收藏夹失败（列表空态）。
struct CollectFolderLoadFailureView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("加载失败", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("重试", action: retry)
        }
    }
}

struct CompactToolbarTextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption2)
            .lineLimit(1)
            .minimumScaleFactor(0.9)
            .fixedSize(horizontal: true, vertical: true)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.55 : 1)
    }
}