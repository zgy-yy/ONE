import SwiftUI

/// 首页顶栏：左日期（点进当月 discovery），右 topText。
struct HomeDayBar: View {
    let day: DayDate
    let topText: String?

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            NavigationLink(value: day) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(day.dayNumberTitle)
                        .font(.largeTitle.weight(.bold))
                    Text(day.monthYearTitle)
                        .font(.title3.weight(.semibold))
                }
                .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 8)

            if let topText {
                Text(topText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
            }

            SearchBarButton()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
    }
}
