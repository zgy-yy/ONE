import SwiftUI

/// 列表封面：全宽 16:9（`one_img` 经 `OneRemoteImage` 加载）。
struct OneCoverImage: View {
    let path: String?

    @State private var uiImage: UIImage?

    var body: some View {
        Color.clear
            .aspectRatio(16 / 9, contentMode: .fit)
            .overlay {
                if let uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Color(.secondarySystemFill)
                        Image(systemName: "photo")
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .contentShape(Rectangle())
            .task(id: path) {
                guard let path, !path.isEmpty else {
                    uiImage = nil
                    return
                }
                // 有缓存时直接回填，避免先清空造成闪一下。
                let image = await OneRemoteImage.load(path: path)
                uiImage = image
            }
    }
}
