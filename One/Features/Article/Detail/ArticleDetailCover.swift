import SwiftUI

/// 详情页顶部封面：按图片原始宽高比铺满宽度；下拉时顶部锚定并放大；GIF 与列表一致可动。
struct ArticleDetailCover: View {
    let path: String?
    /// 图片未就绪时的占位宽高比。
    var placeholderAspect: CGFloat = CoverAspect.landscape
    /// 与外层 `ScrollView` 的 `coordinateSpace` 名称一致。
    var scrollSpace: String = ArticleDetailScrollSpace.name

    @State private var stillImage: UIImage?
    @State private var gifPayload: OneRemoteImage.Payload?

    private let detailMaxPixelSize: CGFloat = 1280

    private var aspectRatio: CGFloat {
        if let stillImage, stillImage.size.height > 0 {
            return stillImage.size.width / stillImage.size.height
        }
        if let data = gifPayload?.data,
           let size = GIFDecoder.pixelSize(data),
           size.height > 0 {
            return size.width / size.height
        }
        if let path, let cached = OneRemoteImage.cachedAspectRatio(for: path) {
            return cached
        }
        return placeholderAspect
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
                stillImage = nil
                gifPayload = nil
                guard let path, !path.isEmpty else { return }

                if let payload = await OneRemoteImage.loadPayload(path: path) {
                    if payload.isGIF {
                        gifPayload = payload
                    } else {
                        stillImage = await OneRemoteImage.load(path: path)
                    }
                }
            }
    }

    @ViewBuilder
    private var coverContent: some View {
        if let gifPayload, gifPayload.isGIF {
            GIFImageView(
                data: gifPayload.data,
                contentMode: .scaleAspectFill,
                fillsContainer: true,
                maxPixelSize: detailMaxPixelSize
            )
        } else if let stillImage {
            Image(uiImage: stillImage)
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