import SwiftUI

/// 演员详情：作品 / 写真 / 评论分段。
struct ActorDetailSegmentTabs: View {
    @Binding var segment: ActorDetailSegment
    var count: (ActorDetailSegment) -> Int?

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ActorDetailSegment.allCases) { item in
                Button {
                    segment = item
                } label: {
                    tabLabel(item)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func tabLabel(_ item: ActorDetailSegment) -> some View {
        let selected = segment == item
        let n = count(item) ?? 0
        return VStack(spacing: 4) {
            Image(systemName: item.systemImage)
                .font(.body.weight(.semibold))
            Text("\(item.rawValue) \(ArticleFormat.shortCount(n))")
                .font(.caption.weight(.medium))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .foregroundStyle(selected ? Color.accentColor : Color.secondary)
        .padding(.vertical, 2)
        .accessibilityLabel("\(item.rawValue) \(n)")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}