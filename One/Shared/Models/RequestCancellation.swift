import Alamofire
import Foundation

extension Error {
    /// 任务 / URLSession / Alamofire 主动取消（下拉刷新卸掉 List、`.task` 换 id 等）。
    var isRequestCancellation: Bool {
        if self is CancellationError { return true }
        if let urlError = self as? URLError, urlError.code == .cancelled { return true }
        if let afError = self as? AFError {
            if afError.isExplicitlyCancelledError { return true }
            if let underlying = afError.underlyingError {
                return underlying.isRequestCancellation
            }
        }
        let nsError = self as NSError
        return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled
    }
}
