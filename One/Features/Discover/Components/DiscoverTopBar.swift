import SwiftUI

/// 发现页顶栏：筛选 + 频道 Tab。
struct DiscoverTopBar: View {
    @Binding var channel: ContentCategory
    @Bindable var session: DiscoverSession

    var body: some View {
        VStack(spacing: 0) {
            if channel.isSeries {
                seriesFilterBar
            } else {
                FilterBar(publishedAt: $session.listPublishedAt, sort: $session.listSort)
            }

            HorizontalCapsuleStrip(
                items: ContentCategory.discoverCases,
                selectedID: channel,
                title: \.title,
                id: \.self,
                onSelect: { channel = $0 }
            )
            Divider()
        }
        .background(Color(.systemBackground))
    }

    private var seriesFilterBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                ForEach(SeriesStatusType.allCases) { item in
                    CapsuleChip(
                        title: item.title,
                        selected: session.seriesStatus == item,
                        compact: true
                    )
                    .onTapGesture { session.seriesStatus = item }
                }
            }

            Spacer(minLength: 8)

            ArticleSortPicker(sort: $session.listSort)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }
}
