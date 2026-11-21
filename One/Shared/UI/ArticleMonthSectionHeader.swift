import SwiftUI

/// `List` 按月分段时的灰色月份头（发现影视等）。
struct ArticleMonthSectionHeader: View {
    let monthAPIString: String

    var body: some View {
        Text(MonthYear.sectionTitle(forAPIString: monthAPIString))
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
    }
}