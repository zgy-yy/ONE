import SwiftUI
import UIKit

/// 详情页底部：列出拼接后的播放地址，可一键复制。
struct ArticlePlayURLFooter: View {
    let entries: [ArticlePlayURL.Entry]

    @State private var copiedURL: String?

    var body: some View {
        if entries.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("播放地址")
                    .font(.subheadline.weight(.semibold))

                ForEach(entries) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.field)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(entry.url)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)

                        Button {
                            UIPasteboard.general.string = entry.url
                            copiedURL = entry.url
                        } label: {
                            Text(copiedURL == entry.url ? "已复制" : "复制")
                                .font(.caption2)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.tint)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }
}
