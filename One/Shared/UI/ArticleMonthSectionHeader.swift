import SwiftUI

/// 按月分段列表的月份标题。
struct ArticleMonthSectionHeader: View {
    let monthAPIString: String
    /// `ScrollView` 吸顶区样式；是否吸顶由 `pinnedViews: [.sectionHeaders]` 决定。
    var stickyChrome: Bool = false

    var body: some View {
        Text(MonthYear.sectionTitle(forAPIString: monthAPIString))
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(nil)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, stickyChrome ? 6 : 4)
            .padding(.horizontal, stickyChrome ? 16 : 0)
            .background(Color.clear)
    }
}
