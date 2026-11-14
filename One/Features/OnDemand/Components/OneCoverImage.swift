import SwiftUI

/// 列表/卡片封面（固定尺寸，`one_img` 经 `OneRemoteImage` 加载）。
struct OneCoverImage: View {
    let path: String?

    @State private var uiImage: UIImage?

    private let size: CGSize

    init(path: String?, size: CGSize = CGSize(width: 88, height: 118)) {
        self.path = path
        self.size = size
    }

    var body: some View {
        Group {
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
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .task(id: path) {
            uiImage = nil
            guard let path, !path.isEmpty else { return }
            uiImage = await OneRemoteImage.load(path: path)
        }
    }
}