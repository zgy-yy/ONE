import SwiftUI

/// 收藏夹行：封面 + 名称 / 篇数 / 累计喜欢数（与 `UserLikeRow` 同宽同高规则）。
struct CollectFolderRow: View {
    let folder: CollectFolder

    private let coverWidth: CGFloat = 152
    private let coverAspect = CoverAspect.landscape

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            OneCoverImage(
                path: folder.imagePath,
                aspectRatio: coverAspect,
                cornerRadius: 8
            )
            .frame(width: coverWidth)

            VStack(alignment: .leading, spacing: 4) {
                Text(folder.displayName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                Spacer(minLength: 0)

                metaRow
            }
            .matchCoverHeight(width: coverWidth, aspect: coverAspect)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metaRow: some View {
        HStack(spacing: 10) {
            MetaIconText.collect(count: folder.articleNum ?? 0)
                .font(.caption2)

            MetaIconText.likes(folder.articleLikeNum ?? 0)
                .font(.caption2)

            Spacer(minLength: 0)
        }
    }
}