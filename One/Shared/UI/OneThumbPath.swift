import Foundation

/// 缩略图路径选择：优先小图，没有再退回原图。
///
/// 接口常同时返回 `thumb` / `thumbnail`，列表用这个 helper 统一取值。
enum OneThumbPath {
    /// 优先缩略图，其次原图；二者皆空则 `nil`。
    static func preferred(thumb: String?, thumbnail: String?) -> String? {
        thumbnail?.nonEmpty ?? thumb?.nonEmpty
    }
}
