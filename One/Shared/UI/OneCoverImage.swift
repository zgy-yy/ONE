import SwiftUI

/// 列表封面（`one_img`）；默认 16:9，竖图传 `CoverAspect.portrait`。
struct OneCoverImage: View {
    let path: String?
    var aspectRatio: CGFloat = CoverAspect.landscape
    /// 为 `true` 时用图片原宽高比；加载前优先用缓存比例，否则 `placeholderAspectRatio`。
    var usesOriginalAspectRatio: Bool = false
    var placeholderAspectRatio: CGFloat = CoverAspect.landscape
    var placeholderSystemName: String = "photo"
    /// 静图列表下采样最长边（与 GIF 封面量级一致）。
    var listMaxPixelSize: CGFloat = 960
    var cornerRadius: CGFloat = 10

    @State private var stillImage: UIImage?
    @State private var gifPayload: OneRemoteImage.Payload?

    private var resolvedAspectRatio: CGFloat {
        guard usesOriginalAspectRatio else { return aspectRatio }
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
        return placeholderAspectRatio
    }

    var body: some View {
        Color.clear
            .aspectRatio(resolvedAspectRatio, contentMode: .fit)
            .overlay { coverContent }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .contentShape(Rectangle())
            .task(id: path) {
                stillImage = nil
                gifPayload = nil
                guard let path, !path.isEmpty else { return }

                if let payload = await OneRemoteImage.loadPayload(path: path) {
                    if payload.isGIF {
                        gifPayload = payload
                    } else {
                        stillImage = await OneRemoteImage.loadListThumbnail(
                            path: path,
                            maxPixelSize: listMaxPixelSize
                        )
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
                maxPixelSize: listMaxPixelSize
            )
        } else if let stillImage {
            Image(uiImage: stillImage).resizable().scaledToFill()
        } else {
            ZStack {
                Color.clear
                Image(systemName: placeholderSystemName)
                    .font(.title3.weight(.light))
                    .foregroundStyle(.quaternary)
            }
        }
    }
}