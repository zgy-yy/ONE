import Foundation
import UIKit

/// 将 HTML 拆成富文本与图片块（`NSAttributedString` + 独立图片视图，无 WebView）。
@MainActor
enum HTMLParser {
    enum Block: Identifiable {
        case richText(AttributedString, id: String)
        case image(path: String, id: String)

        var id: String {
            switch self {
            case .richText(_, let id), .image(_, let id): return id
            }
        }
    }

    private static let imgTagPattern = #"(?is)<img\b[^>]*\bsrc=(['"])(.*?)\1[^>]*>"#

    static func parse(_ html: String) -> [Block] {
        guard !html.isEmpty else { return [] }

        guard let regex = try? NSRegularExpression(pattern: imgTagPattern) else {
            return textOnlyBlocks(html, suffix: "whole")
        }

        let ns = html as NSString
        let matches = regex.matches(in: html, range: NSRange(location: 0, length: ns.length))
        guard !matches.isEmpty else {
            return textOnlyBlocks(html, suffix: "whole")
        }

        var blocks: [Block] = []
        var cursor = 0

        for (index, match) in matches.enumerated() {
            let tagRange = match.range
            if tagRange.location > cursor {
                let textRange = NSRange(location: cursor, length: tagRange.location - cursor)
                appendTextBlocks(from: ns.substring(with: textRange), index: index, into: &blocks)
            }

            if match.numberOfRanges >= 3 {
                let src = ns.substring(with: match.range(at: 2))
                if let path = imageLoadPath(from: src) {
                    blocks.append(.image(path: path, id: "img-\(index)-\(path)"))
                }
            }
            cursor = tagRange.location + tagRange.length
        }

        if cursor < ns.length {
            let tail = NSRange(location: cursor, length: ns.length - cursor)
            appendTextBlocks(from: ns.substring(with: tail), index: matches.count, into: &blocks)
        }

        return blocks
    }

    private static func appendTextBlocks(from fragment: String, index: Int, into blocks: inout [Block]) {
        guard let attributed = attributedString(fromHTMLFragment: fragment) else { return }
        blocks.append(.richText(attributed, id: "text-\(index)"))
    }

    private static func textOnlyBlocks(_ html: String, suffix: String) -> [Block] {
        guard let attributed = attributedString(fromHTMLFragment: html) else { return [] }
        return [.richText(attributed, id: "text-\(suffix)")]
    }

    private static func attributedString(fromHTMLFragment fragment: String) -> AttributedString? {
        let trimmed = fragment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let wrapped = """
        <html><head><meta charset="utf-8"></head>
        <body style="font-family: -apple-system; font-size: 17px;">\(trimmed)</body></html>
        """
        guard let data = wrapped.data(using: .utf8) else { return nil }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue,
        ]

        guard let ns = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            return AttributedString(trimmed)
        }
        return AttributedString(ns)
    }

    private static func imageLoadPath(from src: String) -> String? {
        let trimmed = src.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        if trimmed.lowercased().hasPrefix("data:") { return nil }

        let lower = trimmed.lowercased()
        if lower.hasPrefix("http://") || lower.hasPrefix("https://") {
            guard let url = URL(string: trimmed), isOneImageHost(url) else { return nil }
            return url.path.isEmpty ? "/" : url.path
        }
        return trimmed
    }

    private static func isOneImageHost(_ url: URL) -> Bool {
        guard let base = TokensSession.shared.oneImgCDN,
              !base.isEmpty,
              let baseURL = URL(string: OneCDN.join(base: base, path: "/"))
        else { return false }
        return url.host?.lowercased() == baseURL.host?.lowercased()
    }
}