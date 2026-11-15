import SwiftUI

/// 通用排序切换：发布时间 / 最受欢迎（对应接口 `sort` 字段）。
///
/// 用于点播、发现、演员作品等列表；改文案或顺序时只改 `VodArticleSort`。
struct VodArticleSortPicker: View {
    @Binding var sort: VodArticleSort

    var body: some View {
        Picker("排序", selection: $sort) {
            // `CaseIterable` 的声明顺序即 UI 从左到右的顺序
            ForEach(VodArticleSort.allCases) { item in
                Text(item.title).tag(item)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 200)
        .accessibilityLabel("排序方式")
    }
}
