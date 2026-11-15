import SwiftUI

/// 评论排序：最新 / 最热。
struct CommentSortPicker: View {
    @Binding var sort: CommentSort

    var body: some View {
        Picker("评论排序", selection: $sort) {
            ForEach(CommentSort.allCases) { item in
                Text(item.title).tag(item)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 168)
        .accessibilityLabel("评论排序")
    }
}
