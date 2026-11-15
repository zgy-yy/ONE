import SwiftUI

/// 演员头像：竖图 3:4，走 `one_img` CDN。
struct ActorAvatarImage: View {
    let path: String?

    @State private var uiImage: UIImage?

    var body: some View {
        Color.clear
            .aspectRatio(3 / 4, contentMode: .fit)
            .overlay {
                if let uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Color(.secondarySystemFill)
                        Image(systemName: "person.fill")
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(Rectangle())
            .task(id: path) {
                guard let path, !path.isEmpty else {
                    uiImage = nil
                    return
                }
                uiImage = await OneRemoteImage.load(path: path)
            }
    }
}
