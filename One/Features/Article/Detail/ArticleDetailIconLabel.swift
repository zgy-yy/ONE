import SwiftUI

/// 图标 + 可选中文前缀 + 文字（演员、出品、时长等共用）。
struct ArticleDetailIconLabel: View {
    var prefix: String?
    let systemImage: String
    let text: String
    var emphasized = false
    /// 已喜欢 / 已收藏：图标实心 + 橙色。
    var active = false

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(active ? Color.orange : Color.secondary)
                .frame(width: 20, alignment: .center)

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

    static func actor(_ name: String) -> Self {
        Self(prefix: ArticleDetailSymbol.actorPrefix, systemImage: ArticleDetailSymbol.actor, text: name, emphasized: true)
    }

    static func publisher(_ name: String) -> Self {
        Self(prefix: ArticleDetailSymbol.publisherPrefix, systemImage: ArticleDetailSymbol.publisher, text: name)
    }

    static func volumeIssue(_ vol: Int) -> Self {
        Self(systemImage: ArticleDetailSymbol.volume, text: "第\(vol)期")
    }
}

/// 评论入口（与收藏 / 喜欢同一套图标样式）。
struct ArticleDetailCommentButton: View {
    let count: Int
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ArticleDetailIconLabel(
                prefix: ArticleDetailSymbol.commentPrefix,
                systemImage: ArticleDetailSymbol.comment,
                text: ArticleFormat.shortCount(count)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(ArticleDetailSymbol.commentPrefix) \(count)")
    }
}