import Foundation
import UIKit

/// HTML → 富文本块 + 图片路径块。
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
        guard !html.isEmpty,
              let regex = try? NSRegularExpression(pattern: imgTagPattern)
        else { return textBlock(html, id: "text-whole") }

        let ns = html as NSString
        let matches = regex.matches(in: html, range: NSRange(location: 0, length: ns.length))
        guard !matches.isEmpty else { return textBlock(html, id: "text-whole") }

        var blocks: [Block] = []
        var cursor = 0

        for (index, match) in matches.enumerated() {
            let tagRange = match.range
            if tagRange.location > cursor {
                let range = NSRange(location: cursor, length: tagRange.location - cursor)
                blocks += textBlock(ns.substring(with: range), id: "text-\(index)")
            }
            if match.numberOfRanges >= 3,
               let path = imageLoadPath(from: ns.substring(with: match.range(at: 2)))
            {
                blocks.append(.image(path: path, id: "img-\(index)"))
            }
            cursor = tagRange.location + tagRange.length
        }

        if cursor < ns.length {
            let tail = NSRange(location: cursor, length: ns.length - cursor)
            blocks += textBlock(ns.substring(with: tail), id: "text-tail")
        }
        return blocks
    }

    private static func textBlock(_ fragment: String, id: String) -> [Block] {
        guard !isIgnorableHTMLFragment(fragment),
              let text = attributedString(from: fragment),
              !String(text.characters).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return [] }
        return [.richText(text, id: id)]
    }

    private static func attributedString(from fragment: String) -> AttributedString? {
        let trimmed = fragment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let data = """
              <html><head><meta charset="utf-8"></head>
              <body style="font-family:-apple-system;font-size:17px;margin:0">\(trimmed)</body></html>
              """.data(using: .utf8)
        else { return nil }

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
        if trimmed.isEmpty || trimmed.lowercased().hasPrefix("data:") { return nil }

        if trimmed.lowercased().hasPrefix("http") {
            guard let url = URL(string: trimmed), isOneImageHost(url) else { return nil }
            return url.path.isEmpty ? "/" : url.path
        }
        return trimmed
    }

    private static func isIgnorableHTMLFragment(_ fragment: String) -> Bool {
        var plain = fragment
        for pattern in [#"(?is)<br\s*/?>"#, #"(?is)</?p>"#, #"(?is)</?div>"#, #"(?is)&nbsp;"#, #"(?is)<[^>]+>"#] {
            plain = plain.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }
        return plain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private static func isOneImageHost(_ url: URL) -> Bool {
        guard let base = TokensSession.shared.oneImgCDN, !base.isEmpty,
              let baseURL = URL(string: OneCDN.join(base: base, path: "/"))
        else { return false }
        return url.host?.lowercased() == baseURL.host?.lowercased()
    }
}