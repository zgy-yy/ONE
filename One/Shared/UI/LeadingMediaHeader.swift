import SwiftUI

/// 详情页通用头图布局：左侧固定宽媒体 + 右侧文字信息。
///
/// 演员详情、系列详情等共用，避免各页手写同一套 `HStack`。
struct LeadingMediaHeader<Media: View, Info: View>: View {
    /// 左侧媒体宽度（封面 / 头像）。
    var mediaWidth: CGFloat = 110
    /// 封面与右侧资料间距。
    var mediaSpacing: CGFloat = 14
    @ViewBuilder var media: () -> Media
    @ViewBuilder var info: () -> Info

    var body: some View {
        HStack(alignment: .top, spacing: mediaSpacing) {
            media()
                .frame(width: mediaWidth)
            info()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview("左图右文") {
    LeadingMediaHeader(mediaWidth: 100, mediaSpacing: 8) {
        ActorAvatarImage(path: PreviewSamples.Actor.coverURL)
    } info: {
        VStack(alignment: .leading, spacing: 4) {
            Text("示例标题")
                .font(.headline)
            Text("右侧文字区域")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    .padding()
}
