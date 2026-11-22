import SwiftUI

// MARK: - 排序模型（接口 `sort_dim` / `sort_desc`）

enum CollectFolderSortDimension: String, CaseIterable, Identifiable, Hashable {
    case createTime = "create_time"
    case collectTime = "collect_time"
    case itemCount = "item_count"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .createTime: "创建时间"
        case .collectTime: "收藏时间"
        case .itemCount: "内容数量"
        }
    }
}

struct CollectFolderSort: Equatable {
    var dimension: CollectFolderSortDimension = .createTime
    var descending: Bool = true

    var sortDesc: Int { descending ? 1 : 0 }
}

// MARK: - 顶栏

/// 收藏 Tab 顶栏：滑动胶囊排序 + 新建 + 升序 / 降序。
struct CollectFolderSortBar: View {
    @Binding var sort: CollectFolderSort
    var onCreateFolder: (() -> Void)?

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            SlidingCapsuleSegmented(
                items: Array(CollectFolderSortDimension.allCases),
                title: \.title,
                selection: $sort.dimension
            )
            .frame(maxWidth: .infinity)

            if let onCreateFolder {
                Button(action: onCreateFolder) {
                    Image(systemName: "folder.badge.plus")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 36, height: 36)
                        .background(Color(.tertiarySystemFill), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("新建收藏夹")
            }

            sortOrderButton
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var sortOrderButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                sort.descending.toggle()
            }
        } label: {
            Image(systemName: sort.descending ? "arrow.down" : "arrow.up")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
                .background(Color(.tertiarySystemFill), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(sort.descending ? "降序" : "升序")
    }
}