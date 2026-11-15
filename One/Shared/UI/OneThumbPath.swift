import Foundation

enum OneThumbPath {
    /// 优先缩略图，其次原图。
    static func preferred(thumb: String?, thumbnail: String?) -> String? {
        thumbnail?.nonEmpty ?? thumb?.nonEmpty
    }
}
