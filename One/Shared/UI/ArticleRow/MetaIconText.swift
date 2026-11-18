import SwiftUI

/// 图标 + 文案，间距紧凑，供列表 meta 行复用。
struct MetaIconText: View {
    let systemImage: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
            Text(text)
        }
    }
}
