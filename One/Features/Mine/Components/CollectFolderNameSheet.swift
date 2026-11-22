import SwiftUI

/// 新建或重命名收藏夹（共用表单）。
struct CollectFolderNameSheet: View {
    enum Mode {
        case create
        case rename(CollectFolder)

        var title: String {
            switch self {
            case .create: "新建收藏夹"
            case .rename: "重命名"
            }
        }

        var confirmTitle: String {
            switch self {
            case .create: "创建"
            case .rename: "保存"
            }
        }

        var initialName: String {
            switch self {
            case .create: ""
            case .rename(let folder): folder.displayName
            }
        }
    }

    let mode: Mode
    @Bindable var session: MineLibrarySession
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    init(mode: Mode, session: MineLibrarySession) {
        self.mode = mode
        self.session = session
        _name = State(initialValue: mode.initialName)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canConfirm: Bool {
        guard !trimmedName.isEmpty, !isSubmitting else { return false }
        if case .rename(let folder) = mode {
            return trimmedName != folder.displayName
        }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("收藏夹名称", text: $name)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .disabled(isSubmitting)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(mode.confirmTitle) {
                        Task { await submit() }
                    }
                    .disabled(!canConfirm)
                }
            }
            .interactiveDismissDisabled(isSubmitting)
        }
    }

    private func submit() async {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            switch mode {
            case .create:
                try await session.createCollectFolder(name: trimmedName)
            case .rename(let folder):
                try await session.renameCollectFolder(folderID: folder.id, name: trimmedName)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}