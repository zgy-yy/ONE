import Foundation

extension Array {
    /// 按固定长度切成若干段（末段可不足）。
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0, !isEmpty else { return [] }
        var result: [[Element]] = []
        result.reserveCapacity((count + size - 1) / size)
        var index = startIndex
        while index < endIndex {
            let next = self.index(index, offsetBy: size, limitedBy: endIndex) ?? endIndex
            result.append(Array(self[index..<next]))
            index = next
        }
        return result
    }
}

extension Array where Element == ArticleSummary {
    /// 两列网格行的稳定 `ForEach` id（取行内首篇 id）。
    var rowID: Int { first?.id ?? 0 }
}
