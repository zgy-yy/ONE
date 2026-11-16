import SwiftUI

/// 列表通用筛选：发布年月 + 排序（发布时间 / 最受欢迎）。
struct FilterBar: View {
    @Binding var publishedAt: String
    @Binding var sort: ArticleSort
    @State private var showMonthPicker = false

    var body: some View {
        HStack(spacing: 12) {
            Button {
                showMonthPicker = true
            } label: {
                Label(
                    MonthYear.sectionTitle(forAPIString: publishedAt),
                    systemImage: "calendar"
                )
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("发布年月")

            Spacer(minLength: 8)

            ArticleSortPicker(sort: $sort)
            SearchBarButton()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 4)
        .sheet(isPresented: $showMonthPicker) {
            MonthPickerSheet(month: MonthYear(apiString: publishedAt) ?? .now) { month in
                publishedAt = month.apiString
                showMonthPicker = false
            }
        }
    }
}
