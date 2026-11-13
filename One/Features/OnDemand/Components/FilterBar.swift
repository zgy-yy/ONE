import SwiftUI

struct FilterBar: View {
    @Bindable var session: VodSession
    @State private var showMonthPicker = false
    var body: some View {
        HStack(spacing: 12) {
            Button {
                showMonthPicker = true
            } label: {
                Label(
                    MonthYear.sectionTitle(forAPIString: session.listPublishedAt),
                    systemImage: "calendar"
                )
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("发布年月")

            Spacer(minLength: 8)

            Picker("排序", selection: $session.listSort) {
                ForEach(VodArticleSort.allCases) { sort in
                    Text(sort.title).tag(sort)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 168)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 4)
        .sheet(isPresented: $showMonthPicker) {
            MonthPickerSheet(month: MonthYear(apiString: session.listPublishedAt) ?? .now) { month in
                session.listPublishedAt = month.apiString
                showMonthPicker = false
            }
        }
    }
}
