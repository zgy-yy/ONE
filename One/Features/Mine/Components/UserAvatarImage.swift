import SwiftUI

/// 用户头像：1:1 圆形，走 `one_img` CDN。
struct UserAvatarImage: View {
    let path: String?
    var size: CGFloat = 64

    @State private var uiImage: UIImage?

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color(.secondarySystemFill)
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: size * 0.85))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .contentShape(Circle())
        .task(id: path) {
            guard let path, !path.isEmpty else {
                uiImage = nil
                return
            }
            uiImage = await OneRemoteImage.load(path: path)
        }
    }
}
