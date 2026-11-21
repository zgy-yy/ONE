import SwiftUI

/// 收藏 Tab 顶栏：排序维度 + 升序 / 降序。
struct CollectFolderSortBar: View {
    @Binding var sort: CollectFolderSort

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            TopCapsuleBar(
                items: Array(CollectFolderSortDimension.allCases),
                selectedID: sort.dimension,
                title: \.title,
                id: \.self,
                onSelect: { sort.dimension = $0 }
            )
            .frame(maxWidth: .infinity, alignment: .leading)

            sortOrderButton
                .layoutPriority(1)
        }
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var sortOrderButton: some View {
        Button {
            sort.descending.toggle()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: sort.descending ? "arrow.down" : "arrow.up")
                    .font(.caption.weight(.semibold))
                Text(sort.descending ? "降序" : "升序")
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.tertiarySystemFill), in: Capsule())
        }
        .buttonStyle(.plain)
        .padding(.trailing, 12)
        .accessibilityLabel(sort.descending ? "降序" : "升序")
    }
}