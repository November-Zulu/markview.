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
        let analysis = await MarkdownAnalysis.analyze(text)
        var walker = HighlightWalker(analysis: analysis)
        walker.visit(analysis.document)
        return walker.highlights
    }
}

private struct HighlightWalker: MarkupWalker {
    let analysis: MarkdownAnalysis
    var highlights: [MarkdownHighlighter.Highlight] = []

    /// Returns an NSRange covering only the given 1-based line.
    /// ATX headings are single-line, but the parser can report an extended upperBound
    /// when no blank line follows. This constrains to just the heading line.
    private func nsRangeForLine(_ line: Int) -> NSRange? {
        analysis.nsRange(forLine: line)
    }

    private func nsRange(for markup: Markup) -> NSRange? {
        analysis.nsRange(for: markup)
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
