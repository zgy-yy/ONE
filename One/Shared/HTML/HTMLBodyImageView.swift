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
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .overlay { ProgressView() }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
        .task(id: path) {
            payload = await OneRemoteImage.loadPayload(path: path)
        }
    }

    @ViewBuilder
    private func content(for payload: OneRemoteImage.Payload) -> some View {
        if payload.isGIF {
            GIFImageView(data: payload.data)
                .frame(maxWidth: .infinity)
        } else if let uiImage = UIImage(data: payload.data) {
            let aspect = uiImage.size.height > 0 ? uiImage.size.width / uiImage.size.height : 1
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(aspect, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .clipped()
        }
    }
}
