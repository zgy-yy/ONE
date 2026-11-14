import SwiftUI
import UIKit

/// HTML `<img>`：`OneRemoteImage` 拉取并解密，GIF / 静态图分支展示。
struct HTMLBodyImageView: View {
    let path: String

    @State private var payload: OneRemoteImage.Payload?

    var body: some View {
        Group {
            if let payload {
                content(for: payload)
            } else {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(.secondarySystemFill))
                    .frame(height: 160)
                    .overlay { ProgressView() }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task(id: path) {
            payload = await OneRemoteImage.loadPayload(path: path)
        }
    }

    @ViewBuilder
    private func content(for payload: OneRemoteImage.Payload) -> some View {
        let ratio = Self.displayAspectRatio(data: payload.data)
        if payload.mimeType == "image/gif" {
            GIFImageView(data: payload.data)
                .aspectRatio(ratio, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .clipped()
        } else if let uiImage = UIImage(data: payload.data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
        }
    }

    /// 按像素尺寸算高宽比，超宽图在 `maxWidth: .infinity` 下等比缩小。
    private static func displayAspectRatio(data: Data) -> CGFloat {
        guard let image = UIImage(data: data), image.size.width > 0 else { return 1 }
        return max(image.size.height / image.size.width, 0.05)
    }
}