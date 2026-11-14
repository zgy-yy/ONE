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
        .task(id: path) {
            payload = await OneRemoteImage.loadPayload(path: path)
        }
    }

    @ViewBuilder
    private func content(for payload: OneRemoteImage.Payload) -> some View {
        if payload.mimeType == "image/gif" {
            GIFImageView(data: payload.data)
                .frame(maxWidth: .infinity)
        } else if let uiImage = UIImage(data: payload.data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
        }
    }
}