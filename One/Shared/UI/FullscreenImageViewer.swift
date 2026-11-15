import SwiftUI

/// 全屏图片浏览：左右滑动翻页，点空白 / 关闭按钮退出。
struct FullscreenImageViewer: View {
    let paths: [String]
    @Binding var selection: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $selection) {
                ForEach(Array(paths.enumerated()), id: \.offset) { index, path in
                    FullscreenImagePage(path: path)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))

            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding()
                }
                Spacer()
                if paths.count > 1 {
                    Text("\(selection + 1) / \(paths.count)")
                        .font(.subheadline.monospacedDigit().weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.bottom, 24)
                }
            }
        }
        .statusBarHidden(true)
    }
}

private struct FullscreenImagePage: View {
    let path: String

    @State private var uiImage: UIImage?
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .scaleEffect(scale)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = max(1, min(lastScale * value, 4))
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                    if scale < 1.05 {
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            scale = 1
                                            lastScale = 1
                                        }
                                    }
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if scale > 1.05 {
                                    scale = 1
                                    lastScale = 1
                                } else {
                                    scale = 2.5
                                    lastScale = 2.5
                                }
                            }
                        }
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .task(id: path) {
            uiImage = await OneRemoteImage.load(path: path)
            scale = 1
            lastScale = 1
        }
    }
}
