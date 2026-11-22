import SwiftUI

/// 夹内批量移动：包一层选夹 Sheet。
struct CollectFolderBatchMoveSheet: View {
    let articleIDs: [Int]
    let currentFolderID: Int
    let onSuccess: () -> Void

    var body: some View {
        CollectFolderPickerSheet(
            title: "移动到",
            cancelTitle: "取消",
            disabledFolderID: currentFolderID
        ) { folder in
            try await MineLibrarySession.shared.moveFavorites(
                articleIDs: articleIDs,
                to: folder.id
            )
            onSuccess()
        }
    }
}