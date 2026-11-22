import SwiftUI

/// 演员详情头部：左侧封面 + 右侧资料表。
struct ActorDetailProfileHeader: View {
    let coverPath: String?
    var coverWidth: CGFloat = 160
    var mediaSpacing: CGFloat = 8
    let fields: [Field]
    var showsCollect = false
    var isCollected = false
    var isCollecting = false
    var onCollect: (() -> Void)?

    struct Field: Hashable {
        let icon: String
        let label: String
        let value: String
    }

    var body: some View {
        LeadingMediaHeader(mediaWidth: coverWidth, mediaSpacing: mediaSpacing) {
            ZStack(alignment: .bottomTrailing) {
                ActorAvatarImage(path: coverPath)
                if showsCollect, let onCollect {
                    CoverOverlayIconButton(
                        systemImage: isCollected ? "bookmark.fill" : "bookmark",
                        active: isCollected,
                        isLoading: isCollecting,
                        action: onCollect
                    )
                    .accessibilityLabel(isCollected ? "已收藏演员" : "收藏演员")
                }
            }
        } info: {
            VStack(alignment: .leading, spacing: 3) {
                ForEach(fields, id: \.label) { field in
                    row(field)
                }
            }
        }
    }

    private func row(_ field: Field) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Image(systemName: field.icon)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .frame(width: 12, alignment: .center)
            Text(field.label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .frame(width: 34, alignment: .leading)
            Text(field.value)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(field.label) \(field.value)")
    }
}

#Preview("演员资料头") {
    ActorDetailProfileHeader(
        coverPath: PreviewSamples.Actor.coverURL,
        fields: ActorProfileFields.make(
            detail: PreviewSamples.Actor.detail,
            actor: PreviewSamples.Actor.summary
        ),
        showsCollect: true,
        isCollected: false,
        onCollect: {}
    )
    .padding()
}