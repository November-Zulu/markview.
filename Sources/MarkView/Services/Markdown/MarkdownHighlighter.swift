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

    /// Build an array mapping 1-based line numbers to UTF-8 byte offsets.
    /// lineOffsets[0] is unused, lineOffsets[1] = offset of line 1, etc.
    /// Shared by MarkdownHighlighter and MarkdownLinter.
    static func buildLineOffsets(_ text: String) -> [Int] {
        var offsets = [0, 0] // index 0 unused, line 1 starts at offset 0
        for (i, char) in text.utf8.enumerated() {
            if char == UInt8(ascii: "\n") {
                offsets.append(i + 1)
            }
        }
        return offsets
    }

    /// Convert a UTF-8 byte range (from cmark source positions) to an NSRange
    /// (UTF-16 code units) suitable for NSTextStorage. Critical for documents
    /// containing non-ASCII characters (smart quotes, emoji, accented chars).
    static func utf8RangeToNSRange(start: Int, end: Int, in text: String) -> NSRange? {
        let utf8 = text.utf8
        guard start >= 0, end >= start, end <= utf8.count else { return nil }
        let startIdx = utf8.index(utf8.startIndex, offsetBy: start)
        let endIdx = utf8.index(utf8.startIndex, offsetBy: end)
        return NSRange(startIdx..<endIdx, in: text)
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

        return MarkdownHighlighter.utf8RangeToNSRange(start: start, end: end, in: source)
    }

    /// Returns an NSRange covering only the given 1-based line (up to the newline).
    /// ATX headings are single-line, but the parser can report an extended upperBound
    /// when no blank line follows. This constrains to just the heading line.
    private func nsRangeForLine(_ line: Int) -> NSRange? {
        guard line >= 1, line < lineOffsets.count else { return nil }
        let start = lineOffsets[line]
        let end: Int
        if line + 1 < lineOffsets.count {
            end = lineOffsets[line + 1] - 1 // stop before the \n
        } else {
            end = source.utf8.count
        }
        guard end > start else { return nil }
        return MarkdownHighlighter.utf8RangeToNSRange(start: start, end: end, in: source)
    }

    // MARK: - Headings

    mutating func visitHeading(_ heading: Heading) -> () {
        guard let markupRange = heading.range else { return }
        // ATX headings are single-line; constrain highlight to the start line
        // to prevent the parser's extended upperBound from bleeding color downward.
        if let range = nsRangeForLine(markupRange.lowerBound.line) {
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

    // MARK: - Strikethrough

    mutating func visitStrikethrough(_ strikethrough: Strikethrough) -> () {
        if let range = nsRange(for: strikethrough) {
            highlights.append(.init(
                range: range,
                attributes: [
                    .foregroundColor: DesignTokens.SyntaxColors.strikethrough,
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                ]
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

    // MARK: - Tables

    mutating func visitTable(_ table: Table) -> () {
        if let range = nsRange(for: table) {
            highlights.append(.init(
                range: range,
                attributes: [.foregroundColor: DesignTokens.SyntaxColors.table]
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
