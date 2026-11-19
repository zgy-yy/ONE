import SwiftUI

enum ArticleDetailScrollSpace {
    static let name = "articleDetailScroll"
}

/// 详情通用滚动骨架：顶栏封面 + 下方内容列（宽度锁死，仅纵向滚）。
struct ArticleDetailScrollLayout<Content: View>: View {
    let coverPath: String?
    var placeholderAspect: CGFloat = CoverAspect.landscape
    @ViewBuilder var content: () -> Content

    var body: some View {
        GeometryReader { geo in
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    ArticleDetailCover(
                        path: coverPath,
                        placeholderAspect: placeholderAspect
                    )
                    content()
                }
                .frame(width: geo.size.width, alignment: .leading)
            }
            .coordinateSpace(name: ArticleDetailScrollSpace.name)
        }
        .ignoresSafeArea(edges: .top)
    }
}
