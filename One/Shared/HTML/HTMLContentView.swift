import SwiftUI

/// 原生渲染 HTML：`Text(AttributedString)` + `HTMLBodyImageView`（可复制，无 WebView）。
struct HTMLContentView: View {
    let html: String

    @State private var blocks: [HTMLParser.Block] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(blocks) { block in
                switch block {
                case .richText(let text, _):
                    Text(text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                case .image(let path, _):
                    HTMLBodyImageView(path: path)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .task(id: html) {
            blocks = HTMLParser.parse(html)
        }
    }
}