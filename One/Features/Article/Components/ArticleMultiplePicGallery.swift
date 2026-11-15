import SwiftUI

/// 详情「精彩预览」：定宽分页横滑，避免嵌在竖向 ScrollView 里时卡在两页中间。
struct ArticleMultiplePicGallery: View {
    let paths: [String]

    @State private var pageID: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("精彩预览")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if paths.count > 1 {
                    Text("\(currentPage + 1) / \(paths.count)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.tertiary)
                }
            }

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
        .frame(maxWidth: .infinity, alignment: .leading)
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
