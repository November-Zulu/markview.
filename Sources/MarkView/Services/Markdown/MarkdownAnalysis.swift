import Foundation
import Markdown

/// A parsed markdown document with the metadata needed to translate AST
/// positions and line/byte offsets into NSRanges suitable for NSTextStorage.
/// Shared seam between MarkdownHighlighter and MarkdownLinter.
struct MarkdownAnalysis: Sendable {
    let source: String
    let document: Document
    /// 1-based line → UTF-8 byte offset. Slot 0 is unused; slot count-1 is the
    /// offset just past the final newline (or end of source if no trailing nl).
    let lineOffsets: [Int]

    /// Parse the given text and build the analysis off the main actor.
    static func analyze(_ text: String) async -> MarkdownAnalysis {
        await Task.detached(priority: .userInitiated) {
            MarkdownAnalysis(
                source: text,
                document: Document(parsing: text),
                lineOffsets: lineOffsets(of: text)
            )
        }.value
    }

    /// Compute the line-offset table without parsing. Cheaper than `analyze`
    /// when callers only need byte offsets (e.g. cursor positioning).
    static func lineOffsets(of text: String) -> [Int] {
        var offsets = [0, 0]
        for (i, char) in text.utf8.enumerated() {
            if char == UInt8(ascii: "\n") {
                offsets.append(i + 1)
            }
        }
        return offsets
    }

    /// NSRange for a UTF-8 byte range in `text`, no parsing. Use when only
    /// the conversion is needed and there's no analysis to hand.
    static func nsRange(utf8Start: Int, utf8End: Int, in text: String) -> NSRange? {
        let utf8 = text.utf8
        guard utf8Start >= 0, utf8End >= utf8Start, utf8End <= utf8.count else { return nil }
        let startIdx = utf8.index(utf8.startIndex, offsetBy: utf8Start)
        let endIdx = utf8.index(utf8.startIndex, offsetBy: utf8End)
        return NSRange(startIdx..<endIdx, in: text)
    }

    /// NSRange covering an AST node's source position.
    func nsRange(for markup: Markup) -> NSRange? {
        guard let range = markup.range else { return nil }
        let startLine = range.lowerBound.line
        let startCol = range.lowerBound.column
        let endLine = range.upperBound.line
        let endCol = range.upperBound.column

        guard startLine >= 1, startLine < lineOffsets.count,
              endLine >= 1, endLine < lineOffsets.count else { return nil }

        let utf8Start = lineOffsets[startLine] + (startCol - 1)
        let utf8End = lineOffsets[endLine] + (endCol - 1)
        return nsRange(utf8Start: utf8Start, utf8End: utf8End)
    }

    /// NSRange covering a single 1-based line, excluding the trailing newline.
    /// Returns nil if line is out of bounds or empty.
    func nsRange(forLine line: Int) -> NSRange? {
        guard line >= 1, line < lineOffsets.count else { return nil }
        let start = lineOffsets[line]
        let end: Int
        if line + 1 < lineOffsets.count {
            end = lineOffsets[line + 1] - 1 // stop before \n
        } else {
            end = source.utf8.count
        }
        guard end > start else { return nil }
        return nsRange(utf8Start: start, utf8End: end)
    }

    /// NSRange for a UTF-8 byte range. Returns nil if out of bounds.
    /// Critical for documents containing non-ASCII characters because
    /// NSTextStorage indexes by UTF-16 code units, not UTF-8 bytes.
    func nsRange(utf8Start: Int, utf8End: Int) -> NSRange? {
        let utf8 = source.utf8
        guard utf8Start >= 0, utf8End >= utf8Start, utf8End <= utf8.count else { return nil }
        let startIdx = utf8.index(utf8.startIndex, offsetBy: utf8Start)
        let endIdx = utf8.index(utf8.startIndex, offsetBy: utf8End)
        return NSRange(startIdx..<endIdx, in: source)
    }

    /// Zero-length NSRange at the given UTF-8 offset (for fix insertion points).
    func nsInsertionRange(at utf8Offset: Int) -> NSRange? {
        nsRange(utf8Start: utf8Offset, utf8End: utf8Offset)
    }
}
