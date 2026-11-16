import SwiftUI

/// 列表封面（`one_img`）；默认 16:9，竖图传 `CoverAspect.portrait`。
struct OneCoverImage: View {
    let path: String?
    var aspectRatio: CGFloat = CoverAspect.landscape
    var placeholderSystemName: String = "photo"
    var cornerRadius: CGFloat = 10

    @State private var payload: OneRemoteImage.Payload?

    var body: some View {
        Color.clear
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay { coverContent }
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .contentShape(Rectangle())
            .task(id: path) {
                guard let path, !path.isEmpty else {
                    payload = nil
                    return
                }
                payload = await OneRemoteImage.loadPayload(path: path)
            }
    }

    @ViewBuilder
    private var coverContent: some View {
        if let payload, payload.isGIF {
            GIFImageView(data: payload.data, contentMode: .scaleAspectFill, fillsContainer: true)
        } else if let data = payload?.data, let image = UIImage(data: data) {
            Image(uiImage: image).resizable().scaledToFill()
        } else {
            ZStack {
                Color(.secondarySystemFill)
                Image(systemName: placeholderSystemName).foregroundStyle(.tertiary)
            }
        }
    }
}
