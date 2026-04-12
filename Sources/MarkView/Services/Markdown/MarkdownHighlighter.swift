import AppKit
import Markdown

/// Produces syntax highlighting attributes for markdown text using the swift-markdown AST.
enum MarkdownHighlighter {

    struct Highlight {
        let range: NSRange
        let attributes: [NSAttributedString.Key: Any]
    }

    /// Base attributes applied to all text before highlights.
    static let baseAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
        .foregroundColor: NSColor.labelColor,
    ]

    /// Computes highlight ranges for the given markdown text. Runs off the main actor.
    static func highlights(for text: String) async -> [Highlight] {
        await Task.detached(priority: .userInitiated) {
            let document = Document(parsing: text)
            let lineOffsets = buildLineOffsets(text)
            var walker = HighlightWalker(source: text, lineOffsets: lineOffsets)
            walker.visit(document)
            return walker.highlights
        }.value
    }

    /// Build an array mapping 1-based line numbers to string offsets.
    /// lineOffsets[0] is unused, lineOffsets[1] = offset of line 1, etc.
    private static func buildLineOffsets(_ text: String) -> [Int] {
        var offsets = [0, 0] // index 0 unused, line 1 starts at offset 0
        for (i, char) in text.utf8.enumerated() {
            if char == UInt8(ascii: "\n") {
                offsets.append(i + 1)
            }
        }
        return offsets
    }
}

private struct HighlightWalker: MarkupWalker {
    let source: String
    let lineOffsets: [Int]
    var highlights: [MarkdownHighlighter.Highlight] = []

    private func nsRange(for markup: Markup) -> NSRange? {
        guard let range = markup.range else { return nil }
        let startLine = range.lowerBound.line
        let startCol = range.lowerBound.column
        let endLine = range.upperBound.line
        let endCol = range.upperBound.column

        guard startLine >= 1, startLine < lineOffsets.count,
              endLine >= 1, endLine < lineOffsets.count else { return nil }

        let start = lineOffsets[startLine] + (startCol - 1)
        let end = lineOffsets[endLine] + (endCol - 1)
        let length = source.utf8.count

        guard start >= 0, end >= start, end <= length else { return nil }
        return NSRange(location: start, length: end - start)
    }

    // MARK: - Headings

    mutating func visitHeading(_ heading: Heading) -> () {
        if let range = nsRange(for: heading) {
            let color: NSColor = switch heading.level {
            case 1: DesignTokens.SyntaxColors.heading1
            case 2: DesignTokens.SyntaxColors.heading2
            case 3: DesignTokens.SyntaxColors.heading3
            default: DesignTokens.SyntaxColors.headingOther
            }
            highlights.append(.init(
                range: range,
                attributes: [.foregroundColor: color]
            ))
        }
        // No descendInto — heading gets uniform color across the full line
    }

    // MARK: - Inline emphasis

    mutating func visitStrong(_ strong: Strong) -> () {
        if let range = nsRange(for: strong) {
            highlights.append(.init(
                range: range,
                attributes: [.foregroundColor: DesignTokens.SyntaxColors.strong]
            ))
        }
        // No descendInto — avoids child highlights overriding/overflowing
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) -> () {
        if let range = nsRange(for: emphasis) {
            highlights.append(.init(
                range: range,
                attributes: [.foregroundColor: DesignTokens.SyntaxColors.emphasis]
            ))
        }
    }

    // MARK: - Code

    mutating func visitInlineCode(_ inlineCode: InlineCode) -> () {
        if let range = nsRange(for: inlineCode) {
            highlights.append(.init(
                range: range,
                attributes: [.foregroundColor: DesignTokens.SyntaxColors.inlineCode]
            ))
        }
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> () {
        if let range = nsRange(for: codeBlock) {
            highlights.append(.init(
                range: range,
                attributes: [.foregroundColor: DesignTokens.SyntaxColors.codeBlock]
            ))
        }
    }

    // MARK: - Links

    mutating func visitLink(_ link: Link) -> () {
        if let range = nsRange(for: link) {
            highlights.append(.init(
                range: range,
                attributes: [
                    .foregroundColor: DesignTokens.SyntaxColors.link,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                ]
            ))
        }
    }

    // MARK: - Block quotes

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) -> () {
        if let range = nsRange(for: blockQuote) {
            highlights.append(.init(
                range: range,
                attributes: [
                    .foregroundColor: DesignTokens.SyntaxColors.blockQuote,
                ]
            ))
        }
        descendInto(blockQuote)
    }

    // MARK: - Lists

    mutating func visitListItem(_ listItem: ListItem) -> () {
        // Don't highlight list markers — the AST range covers content only, not the
        // marker character, so coloring the first N chars would color content text.
        descendInto(listItem)
    }
}
