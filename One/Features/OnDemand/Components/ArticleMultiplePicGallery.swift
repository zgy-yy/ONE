import SwiftUI

/// 详情「精彩预览」：`multiple_pic` 横向滑动（`one_img` + 解密）。
struct ArticleMultiplePicGallery: View {
    let paths: [String]

    @State private var page = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("精彩预览")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if paths.count > 1 {
                    Text("\(page + 1) / \(paths.count)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.tertiary)
                }
            }

            TabView(selection: $page) {
                ForEach(Array(paths.enumerated()), id: \.offset) { index, path in
                    ArticleGalleryImage(path: path)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: paths.count > 1 ? .automatic : .never))
            .frame(height: 320)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ArticleGalleryImage: View {
    let path: String

    @State private var uiImage: UIImage?

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(.secondarySystemFill))
                    .overlay {
                        ProgressView()
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.horizontal, 2)
        .task(id: path) {
            uiImage = await OneRemoteImage.load(path: path)
        }
    }
}