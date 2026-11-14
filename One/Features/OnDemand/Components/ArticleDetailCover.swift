import SwiftUI

/// 详情页顶部视频封面（SenPlayer 风格：只展示海报，不内嵌播放）。
struct ArticleDetailCover: View {
    let path: String?

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
                    Image(systemName: "film")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(16 / 9, contentMode: .fit)
        .clipped()
        .task(id: path) {
            uiImage = nil
            guard let path, !path.isEmpty else { return }
            uiImage = await OneRemoteImage.load(path: path)
        }
    }
}
