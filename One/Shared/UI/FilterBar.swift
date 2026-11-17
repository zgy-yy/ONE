import SwiftUI

/// 列表通用筛选：发布年月 + 排序（发布时间 / 最受欢迎）。
struct FilterBar: View {
    @Binding var publishedAt: String
    @Binding var sort: ArticleSort
    @State private var showMonthPicker = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button {
                    withAnimation(.snappy) {
                        showMonthPicker.toggle()
                    }
                } label: {
                    Label(
                        MonthYear.sectionTitle(forAPIString: publishedAt),
                        systemImage: "calendar"
                    )
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)

                Spacer(minLength: 8)

                ArticleSortPicker(sort: $sort)
                SearchBarButton()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 4)

            if showMonthPicker {
                MonthPickerSheet(month: MonthYear(apiString: publishedAt) ?? .now) { month in
                    publishedAt = month.apiString
                    withAnimation(.snappy) {
                        showMonthPicker = false
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .clipped()
    }
}
