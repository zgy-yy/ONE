import SwiftUI

/// 详情「精彩预览」：定宽分页横滑。
/// 点播标题行：左日期 / 中「精彩预览」 / 右评论。
struct ArticleMultiplePicGallery: View {
    let paths: [String]
    var commentCount: Int? = nil
    var onCommentsTap: (() -> Void)? = nil
    /// 放在标题行左侧的日期文案（点播）。
    var headerDate: String? = nil

    @State private var pageID: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerRow

            if !paths.isEmpty {
                GeometryReader { geo in
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 0) {
                            ForEach(Array(paths.enumerated()), id: \.offset) { index, path in
                                ArticleGalleryImage(path: path)
                                    .frame(width: geo.size.width, height: geo.size.height)
                                    .id(index)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    .scrollPosition(id: $pageID)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .frame(height: 320)
                .onAppear {
                    if pageID == nil {
                        pageID = 0
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var headerRow: some View {
        HStack(spacing: 8) {
            leftHeader
                .frame(maxWidth: .infinity, alignment: .leading)

            centerHeader

            rightHeader
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    @ViewBuilder
    private var leftHeader: some View {
        if let headerDate {
            ArticleDetailIconLabel(systemImage: "calendar", text: headerDate)
        }
    }

    private var centerHeader: some View {
        HStack(spacing: 8) {
            Text("精彩预览")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            if !paths.isEmpty {
                Text("\(currentPage + 1) / \(paths.count)")
                    .font(.subheadline.monospacedDigit().weight(.medium))
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("第 \(currentPage + 1) 张，共 \(paths.count) 张")
            }
        }
    }

    @ViewBuilder
    private var rightHeader: some View {
        if let onCommentsTap {
            Button(action: onCommentsTap) {
                HStack(spacing: 5) {
                    Image(systemName: "bubble.left.and.bubble.right")
                    Text("评论")
                    Text(ArticleFormat.shortCount(commentCount ?? 0))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
            .accessibilityLabel("评论 \(commentCount ?? 0)")
        }
    }

    private var currentPage: Int {
        min(max(pageID ?? 0, 0), max(paths.count - 1, 0))
    }
}

private struct ArticleGalleryImage: View {
    let path: String

    @State private var uiImage: UIImage?

    var body: some View {
        ZStack {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .contentShape(Rectangle())
        .task(id: path) {
            uiImage = await OneRemoteImage.load(path: path)
        }
    }
}
