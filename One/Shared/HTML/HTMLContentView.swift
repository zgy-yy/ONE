import SwiftUI

/// 原生渲染 HTML：`Text(AttributedString)` + `HTMLBodyImageView`。
struct HTMLContentView: View {
    let html: String

    @State private var blocks: [HTMLParser.Block] = []

    private enum Spacing {
        static let text: CGFloat = 10
        static let betweenImages: CGFloat = 6
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(blocks.enumerated()), id: \.element.id) { index, block in
                blockView(block)
                    .padding(.top, index == 0 ? 0 : gap(after: blocks[index - 1], before: block))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .task(id: html) { blocks = HTMLParser.parse(html) }
    }

    @ViewBuilder
    private func blockView(_ block: HTMLParser.Block) -> some View {
        switch block {
        case .richText(let text, _):
            Text(text)
                // 解析时已去掉 HTML 死黑字色，这里用语义色适配深浅色
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        case .image(let path, _):
            HTMLBodyImageView(path: path)
        }
    }

    private func gap(after previous: HTMLParser.Block, before current: HTMLParser.Block) -> CGFloat {
        if case .image = previous, case .image = current { return Spacing.betweenImages }
        return Spacing.text
    }
}