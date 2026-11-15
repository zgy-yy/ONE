import SwiftUI

/// 按月分段列表的月份标题。
struct ArticleMonthSectionHeader: View {
    let monthAPIString: String
    /// `ScrollView` 吸顶时铺底，避免内容透出。
    var pinned: Bool = false

    var body: some View {
        Text(MonthYear.sectionTitle(forAPIString: monthAPIString))
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(nil)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, pinned ? 6 : 4)
            .padding(.horizontal, pinned ? 16 : 0)
            .background(pinned ? Color(.systemBackground) : Color.clear)
    }
}
