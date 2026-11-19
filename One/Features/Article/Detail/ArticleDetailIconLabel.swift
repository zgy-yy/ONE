import SwiftUI

/// 图标 + 可选中文前缀 + 文字（演员、发行、时长等共用）。
struct ArticleDetailIconLabel: View {
    var prefix: String?
    let systemImage: String
    let text: String
    var emphasized = false
    /// 已喜欢 / 已收藏：图标用实心 + 橙色。
    var active = false

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(active ? Color.orange : Color.secondary)
                .frame(width: 18, alignment: .center)

            if let prefix {
                Text(prefix)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Text(text)
                .font(emphasized ? .subheadline.weight(.medium) : .subheadline)
                .foregroundStyle(emphasized ? Color.primary : Color.secondary)
                .lineLimit(2)
        }
    }
}
