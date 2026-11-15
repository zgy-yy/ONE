import SwiftUI

/// 详情「精彩预览」：定宽分页横滑；标题行右侧为图片数量，再右侧为可点评论入口。
struct ArticleMultiplePicGallery: View {
    let paths: [String]
    var commentCount: Int? = nil
    var onCommentsTap: (() -> Void)? = nil

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
        HStack(spacing: 12) {
            Text("精彩预览")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            if !paths.isEmpty {
                // 当前页 / 总数，例如 3 / 12
                Text("\(currentPage + 1) / \(paths.count)")
                    .font(.subheadline.monospacedDigit().weight(.medium))
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("第 \(currentPage + 1) 张，共 \(paths.count) 张")
            }

            Spacer(minLength: 8)

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
