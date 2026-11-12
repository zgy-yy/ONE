import SwiftUI
import UIKit

/// 异步加载列表封面。
///
/// 流程：splash 里的 `one_img` 基址 + 接口返回的 `thumb` 相对路径 → 下载
/// → 若是 JPEG/PNG 魔数则直接显示，否则 AES 解密后再 `UIImage` 展示。
///
/// - `@State uiImage`：加载完成后触发界面更新。
/// - `URLSession.shared.data(from:)`：系统提供的简单 GET 下载（与 Alamofire 并存无妨）。
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
                    Color(white: 0.12)
                    Image(systemName: "photo")
                        .foregroundStyle(Color(white: 0.35))
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .task(id: path) {
            await load()
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
