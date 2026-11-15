import SwiftUI

/// 列表封面（`one_img` 经 `OneRemoteImage` 加载）。
/// 默认 16:9；竖图场景传 `CoverAspect.portrait`。
struct OneCoverImage: View {
    let path: String?
    var aspectRatio: CGFloat = CoverAspect.landscape
    var placeholderSystemName: String = "photo"
    var cornerRadius: CGFloat = 10

    @State private var uiImage: UIImage?

    var body: some View {
        Color.clear
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay {
                if let uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Color(.secondarySystemFill)
                        Image(systemName: placeholderSystemName)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .contentShape(Rectangle())
            .task(id: path) {
                guard let path, !path.isEmpty else {
                    uiImage = nil
                    return
                }
                // 有缓存时直接回填，避免先清空造成闪一下。
                uiImage = await OneRemoteImage.load(path: path)
            }
    }
}
