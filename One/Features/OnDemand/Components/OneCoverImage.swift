import SwiftUI
import UIKit

struct OneCoverImage: View {
    let path: String?

    @State private var uiImage: UIImage?

    private let size: CGSize

    init(path: String?, size: CGSize = CGSize(width: 88, height: 118)) {
        self.path = path
        self.size = size
    }

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color(.secondarySystemFill)
                    Image(systemName: "photo")
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .task(id: path) {
            // await load()
        }
    }

    @MainActor
    private func load() async {
        uiImage = nil
        guard let path, !path.isEmpty else { return }
        guard let base = TokensSession.shared.oneImgCDN, !base.isEmpty else { return }
        let urlString = OneCDN.join(base: base, path: path)
        guard let url = URL(string: urlString) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let imageData: Data
            if OneImageCrypto.isPlainImage(data) {
                imageData = data
            } else {
                imageData = try OneImageCrypto.decrypt(cipher: data)
            }
            uiImage = UIImage(data: imageData)
        } catch {
            uiImage = nil
        }
    }
}
