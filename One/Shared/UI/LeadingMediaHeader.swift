import SwiftUI

/// 详情页通用头图布局：左侧固定宽媒体 + 右侧文字信息。
///
/// 演员详情、系列详情等共用，避免各页手写同一套 `HStack`。
struct LeadingMediaHeader<Media: View, Info: View>: View {
    /// 左侧媒体宽度（封面 / 头像）。
    var mediaWidth: CGFloat = 110
    @ViewBuilder var media: () -> Media
    @ViewBuilder var info: () -> Info

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            media()
                .frame(width: mediaWidth)
            info()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
