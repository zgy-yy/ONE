import SwiftUI

/// 图标 + 可选中文前缀 + 文字（演员、发行、时长等共用）。
struct ArticleDetailIconLabel: View {
    var prefix: String?
    let systemImage: String
    let text: String
    var emphasized = false

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .frame(width: 14)
            if let prefix {
                Text(prefix)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Text(text)
                .font(emphasized ? .subheadline.weight(.medium) : .subheadline)
                .foregroundStyle(emphasized ? .primary : .secondary)
                .lineLimit(2)
        }
    }
}