import SwiftUI

/// 系列连载状态切换：全部 / 连载中 / 已完结（对应接口 `type`）。
struct SeriesStatusPicker: View {
    @Binding var status: SeriesStatusType

    var body: some View {
        Picker("连载状态", selection: $status) {
            ForEach(SeriesStatusType.allCases) { item in
                Text(item.title).tag(item)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 240)
        .accessibilityLabel("连载状态")
    }
}
