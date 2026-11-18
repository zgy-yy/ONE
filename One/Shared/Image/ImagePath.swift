import Foundation

/// 封面 / 头像路径选择。
///
/// 接口常同时返回：
/// - `thumb`：原图 / 大图
/// - `thumbnail`：压缩小图，适合列表快速加载
enum ImagePath {
    /// 列表用：优先小图，没有再退回原图。
    static func preferred(thumb: String?, thumbnail: String?) -> String? {
        thumbnail?.nonEmpty ?? thumb?.nonEmpty
    }

    /// 详情封面用：优先原图 `thumb`，更清晰；没有再退回小图。
    static func full(thumb: String?, thumbnail: String?) -> String? {
        thumb?.nonEmpty ?? thumbnail?.nonEmpty
    }
}
