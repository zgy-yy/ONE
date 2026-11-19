import SwiftUI

/// 详情页顶部封面：按图片原始宽高比铺满宽度；下拉时顶部锚定并放大。
struct ArticleDetailCover: View {
    let path: String?
    /// 图片未就绪时的占位宽高比。
    var placeholderAspect: CGFloat = CoverAspect.landscape
    /// 与外层 `ScrollView` 的 `coordinateSpace` 名称一致。
    var scrollSpace: String = ArticleDetailScrollSpace.name

    @State private var uiImage: UIImage?

    private var aspectRatio: CGFloat {
        guard let uiImage, uiImage.size.height > 0 else { return placeholderAspect }
        return uiImage.size.width / uiImage.size.height
    }

    var body: some View {
        Color.clear
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay(alignment: .top) {
                GeometryReader { geo in
                    let pull = max(0, geo.frame(in: .named(scrollSpace)).minY)
                    coverContent
                        .frame(width: geo.size.width, height: geo.size.height + pull)
                        .clipped()
                        .offset(y: -pull)
                }
            }
            .task(id: path) {
                guard let path, !path.isEmpty else {
                    uiImage = nil
                    return
                }
                uiImage = await OneRemoteImage.load(path: path)
            }
    }

    @ViewBuilder
    private var coverContent: some View {
        if let uiImage {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Color(.secondarySystemFill)
                Image(systemName: "photo")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
