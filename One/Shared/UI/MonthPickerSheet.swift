import SwiftUI

/// 年月滚轮（仅数字，无「年/月」后缀）。
struct MonthPickerSheet: View {
    @State private var selection: MonthYear
    var onConfirm: (MonthYear) -> Void

    init(month: MonthYear, onConfirm: @escaping (MonthYear) -> Void) {
        _selection = State(initialValue: month.clamped())
        self.onConfirm = onConfirm
    }

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                Picker("", selection: $selection.year) {
                    ForEach(MonthYear.selectableYears, id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)

                Picker("", selection: $selection.month) {
                    ForEach(MonthYear(year: selection.year, month: 1).selectableMonths, id: \.self) { month in
                        Text(String(format: "%02d", month)).tag(month)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            .navigationTitle("发布年月")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        onConfirm(selection.clamped())
                    }
                }
            }
            .onChange(of: selection.year) { _, _ in
                selection = selection.clamped()
            }
        }
        .frame(height: 280)
        .background(Color(.systemBackground))
    }
}

private extension MonthYear {
    func clamped() -> MonthYear {
        MonthYear.clamped(year: year, month: month)
    }
}
