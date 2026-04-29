import Foundation
import Markdown

// MARK: - Public types

enum LintRule: String, CaseIterable, Sendable {
    case atxHeadingSpace
    case blankLineAroundHeading
    case headingHierarchy
    case trailingWhitespace
    case consecutiveBlankLines
    case noEmptyLinks
    case blankLineAroundCodeBlock
    case blankLineAroundBlockQuote
    case consistentListMarker
    case noTrailingHashHeading

    var displayName: String {
        switch self {
        case .atxHeadingSpace: "atx-heading-space"
        case .blankLineAroundHeading: "blank-line-around-heading"
        case .headingHierarchy: "heading-hierarchy"
        case .trailingWhitespace: "trailing-whitespace"
        case .consecutiveBlankLines: "consecutive-blank-lines"
        case .noEmptyLinks: "no-empty-links"
        case .blankLineAroundCodeBlock: "blank-line-around-code-block"
        case .blankLineAroundBlockQuote: "blank-line-around-block-quote"
        case .consistentListMarker: "consistent-list-marker"
        case .noTrailingHashHeading: "no-trailing-hash-heading"
        }
    }
}

struct LintFix: Sendable {
    let range: NSRange
    let replacement: String
}

struct LintViolation: Identifiable, Equatable, Sendable {
    static func == (lhs: LintViolation, rhs: LintViolation) -> Bool {
        lhs.id == rhs.id
    }

    let id = UUID()
    let rule: LintRule
    let line: Int
    let column: Int
    let message: String
    let fix: LintFix?
    /// Range in the source text to underline in the editor (full line).
    var underlineRange: NSRange? = nil
}

// MARK: - Linter engine

enum MarkdownLinter {

    /// Lint the given markdown text and return violations sorted by line number.
    static func lint(_ text: String) async -> [LintViolation] {
        let analysis = await MarkdownAnalysis.analyze(text)
        let lines = text.splitLines()

        // Pass 1: AST-based rules
        var walker = LintWalker(analysis: analysis, lines: lines)
        walker.visit(analysis.document)
        var violations = walker.violations

        // Pass 2: Line-based rules
        violations.append(contentsOf: checkTrailingWhitespace(lines, analysis: analysis))
        violations.append(contentsOf: checkConsecutiveBlankLines(lines, analysis: analysis))
        violations.append(contentsOf: checkAtxHeadingSpace(lines, analysis: analysis))

        violations.sort { $0.line < $1.line }

        // Compute underline ranges for each violation (full line)
        for i in violations.indices {
            violations[i].underlineRange = analysis.nsRange(forLine: violations[i].line)
        }

        return violations
    }

    /// Apply all fixable violations to the text. Returns the corrected string.
    /// Violations must have been produced for exactly this text (caller should
    /// guard against stale violations).
    static func applyFixes(to text: String, violations: [LintViolation]) -> String {
        let fixes = violations
            .compactMap(\.fix)
            .sorted { $0.range.location > $1.range.location }

        var result = text
        for fix in fixes {
            guard let swiftRange = Range(fix.range, in: result) else { continue }
            result.replaceSubrange(swiftRange, with: fix.replacement)
        }
        return result
    }
}

// MARK: - Line-based rules

private extension MarkdownLinter {

    /// Detects lines like `#Heading` where there's no space after the `#` markers.
    /// This must be line-based because cmark-gfm doesn't parse `#Heading` as a heading.
    static func checkAtxHeadingSpace(_ lines: [String], analysis: MarkdownAnalysis) -> [LintViolation] {
        var violations: [LintViolation] = []
        let lineOffsets = analysis.lineOffsets
        for (i, line) in lines.enumerated() {
            let lineNum = i + 1
            let trimmed = line.drop(while: \.isWhitespace)
            let hashCount = trimmed.prefix(while: { $0 == "#" }).count
            guard hashCount >= 1, hashCount <= 6 else { continue }
            let afterHashes = trimmed.dropFirst(hashCount)
            if afterHashes.isEmpty { continue }
            if afterHashes.first == " " { continue }
            let utf8Offset = lineNum < lineOffsets.count
                ? lineOffsets[lineNum] + line.prefix(while: \.isWhitespace).utf8.count + hashCount
                : hashCount
            violations.append(LintViolation(
                rule: .atxHeadingSpace,
                line: lineNum,
                column: hashCount + 1,
                message: "No space after '#' in heading",
                fix: analysis.nsInsertionRange(at: utf8Offset)
                    .map { LintFix(range: $0, replacement: " ") }
            ))
        }
        return violations
    }

    static func checkTrailingWhitespace(_ lines: [String], analysis: MarkdownAnalysis) -> [LintViolation] {
        var violations: [LintViolation] = []
        let lineOffsets = analysis.lineOffsets
        for (i, line) in lines.enumerated() {
            let lineNum = i + 1
            let trimmed = line.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
            let trailingCount = line.count - trimmed.count
            if trailingCount > 0 {
                if trailingCount == 2 && line.hasSuffix("  ") { continue }
                let lineStart = lineNum < lineOffsets.count ? lineOffsets[lineNum] : 0
                let fixStart = lineStart + trimmed.utf8.count
                let fixEnd = lineStart + line.utf8.count
                violations.append(LintViolation(
                    rule: .trailingWhitespace,
                    line: lineNum,
                    column: trimmed.count + 1,
                    message: "Trailing whitespace",
                    fix: analysis.nsRange(utf8Start: fixStart, utf8End: fixEnd)
                        .map { LintFix(range: $0, replacement: "") }
                ))
            }
        }
        return violations
    }

    static func checkConsecutiveBlankLines(_ lines: [String], analysis: MarkdownAnalysis) -> [LintViolation] {
        var violations: [LintViolation] = []
        let lineOffsets = analysis.lineOffsets
        let source = analysis.source
        var blankRun = 0
        for (i, line) in lines.enumerated() {
            if line.allSatisfy(\.isWhitespace) {
                blankRun += 1
            } else {
                if blankRun > 1 {
                    let runStart = i - blankRun
                    let startLine = runStart + 1
                    let keepLine = startLine
                    let keepEnd = keepLine + 1 < lineOffsets.count ? lineOffsets[keepLine + 1] : 0
                    let endLine = i
                    let fixEndOffset = endLine + 1 < lineOffsets.count ? lineOffsets[endLine + 1] : keepEnd
                    if fixEndOffset > keepEnd {
                        violations.append(LintViolation(
                            rule: .consecutiveBlankLines,
                            line: startLine,
                            column: 1,
                            message: "Multiple consecutive blank lines",
                            fix: analysis.nsRange(utf8Start: keepEnd, utf8End: fixEndOffset)
                                .map { LintFix(range: $0, replacement: "") }
                        ))
                    }
                }
                blankRun = 0
            }
        }
        if blankRun > 1 {
            let runStart = lines.count - blankRun
            let startLine = runStart + 1
            let keepEnd = startLine + 1 < lineOffsets.count ? lineOffsets[startLine + 1] : 0
            let fileEnd = source.utf8.count
            if fileEnd > keepEnd {
                violations.append(LintViolation(
                    rule: .consecutiveBlankLines,
                    line: startLine,
                    column: 1,
                    message: "Multiple consecutive blank lines",
                    fix: analysis.nsRange(utf8Start: keepEnd, utf8End: fileEnd)
                        .map { LintFix(range: $0, replacement: "") }
                ))
            }
        }
        return violations
    }
}

// MARK: - AST walker

struct LintWalker: MarkupWalker {
    let analysis: MarkdownAnalysis
    let lines: [String]
    var violations: [LintViolation] = []

    private var lastHeadingLevel: Int = 0
    private var listMarkers: [(marker: Character, line: Int)] = []

    init(analysis: MarkdownAnalysis, lines: [String]) {
        self.analysis = analysis
        self.lines = lines
    }

    private var lineOffsets: [Int] { analysis.lineOffsets }
    private var source: String { analysis.source }

    // MARK: Headings

    mutating func visitHeading(_ heading: Heading) {
        guard let range = heading.range else {
            descendInto(heading)
            return
        }
        let lineIdx = range.lowerBound.line - 1 // 0-based
        guard lineIdx >= 0, lineIdx < lines.count else {
            descendInto(heading)
            return
        }
        let rawLine = lines[lineIdx]

        // no-trailing-hash-heading: remove trailing # characters
        let trimmedEnd = rawLine.replacingOccurrences(of: "\\s+#+\\s*$", with: "", options: .regularExpression)
        if trimmedEnd.count < rawLine.count, rawLine.contains("# ") {
            let fixStart = lineOffsets[range.lowerBound.line] + trimmedEnd.utf8.count
            let fixEnd = lineOffsets[range.lowerBound.line] + rawLine.utf8.count
            violations.append(LintViolation(
                rule: .noTrailingHashHeading,
                line: range.lowerBound.line,
                column: trimmedEnd.count + 1,
                message: "Trailing '#' characters on heading",
                fix: analysis.nsRange(utf8Start: fixStart, utf8End: fixEnd)
                    .map { LintFix(range: $0, replacement: "") }
            ))
        }

        // blank-line-around-heading
        let prevLineIdx = lineIdx - 1
        if prevLineIdx >= 0 {
            let prevLine = lines[prevLineIdx]
            if !prevLine.allSatisfy(\.isWhitespace) {
                let insertOffset = lineOffsets[range.lowerBound.line]
                violations.append(LintViolation(
                    rule: .blankLineAroundHeading,
                    line: range.lowerBound.line,
                    column: 1,
                    message: "Heading should be preceded by a blank line",
                    fix: analysis.nsInsertionRange(at: insertOffset)
                        .map { LintFix(range: $0, replacement: "\n") }
                ))
            }
        }
        // ATX headings are single-line; use the start line (not upperBound which
        // the parser can extend when no blank line follows the heading).
        let nextLineIdx = lineIdx + 1
        if nextLineIdx < lines.count {
            let nextLine = lines[nextLineIdx]
            if !nextLine.allSatisfy(\.isWhitespace) {
                let headingLineEnd = range.lowerBound.line + 1 < lineOffsets.count
                    ? lineOffsets[range.lowerBound.line + 1]
                    : source.utf8.count
                violations.append(LintViolation(
                    rule: .blankLineAroundHeading,
                    line: range.lowerBound.line,
                    column: lines[lineIdx].count + 1,
                    message: "Heading should be followed by a blank line",
                    fix: analysis.nsInsertionRange(at: headingLineEnd)
                        .map { LintFix(range: $0, replacement: "\n") }
                ))
            }
        }

        // heading-hierarchy
        if lastHeadingLevel > 0, heading.level > lastHeadingLevel + 1 {
            violations.append(LintViolation(
                rule: .headingHierarchy,
                line: range.lowerBound.line,
                column: 1,
                message: "Heading level jumped from h\(lastHeadingLevel) to h\(heading.level)",
                fix: nil
            ))
        }
        lastHeadingLevel = heading.level

        descendInto(heading)
    }

    // MARK: Links

    mutating func visitLink(_ link: Markdown.Link) {
        guard let range = link.range else {
            descendInto(link)
            return
        }
        let destination = link.destination ?? ""
        let linkText = link.plainText

        if destination.isEmpty {
            violations.append(LintViolation(
                rule: .noEmptyLinks,
                line: range.lowerBound.line,
                column: range.lowerBound.column,
                message: "Link has empty destination",
                fix: nil
            ))
        }
        if linkText.trimmingCharacters(in: .whitespaces).isEmpty {
            violations.append(LintViolation(
                rule: .noEmptyLinks,
                line: range.lowerBound.line,
                column: range.lowerBound.column,
                message: "Link has empty text",
                fix: nil
            ))
        }
        descendInto(link)
    }

    // MARK: Code blocks

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) {
        guard let range = codeBlock.range else { return }
        let lineIdx = range.lowerBound.line - 1

        let prevLineIdx = lineIdx - 1
        if prevLineIdx >= 0, prevLineIdx < lines.count {
            let prevLine = lines[prevLineIdx]
            if !prevLine.allSatisfy(\.isWhitespace) {
                violations.append(LintViolation(
                    rule: .blankLineAroundCodeBlock,
                    line: range.lowerBound.line,
                    column: 1,
                    message: "Code block should be preceded by a blank line",
                    fix: analysis.nsInsertionRange(at: lineOffsets[range.lowerBound.line])
                        .map { LintFix(range: $0, replacement: "\n") }
                ))
            }
        }
        let endLineIdx = range.upperBound.line - 1
        let nextLineIdx = endLineIdx + 1
        if nextLineIdx < lines.count, nextLineIdx >= 0 {
            let nextLine = lines[nextLineIdx]
            if !nextLine.allSatisfy(\.isWhitespace) {
                let insertUTF8 = lineOffsets[range.upperBound.line] + (range.upperBound.column - 1)
                violations.append(LintViolation(
                    rule: .blankLineAroundCodeBlock,
                    line: range.upperBound.line,
                    column: range.upperBound.column,
                    message: "Code block should be followed by a blank line",
                    fix: analysis.nsInsertionRange(at: insertUTF8)
                        .map { LintFix(range: $0, replacement: "\n") }
                ))
            }
        }
    }

    // MARK: Block quotes

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) {
        guard let range = blockQuote.range else {
            descendInto(blockQuote)
            return
        }
        let lineIdx = range.lowerBound.line - 1

        let prevLineIdx = lineIdx - 1
        if prevLineIdx >= 0, prevLineIdx < lines.count {
            let prevLine = lines[prevLineIdx]
            if !prevLine.allSatisfy(\.isWhitespace) {
                violations.append(LintViolation(
                    rule: .blankLineAroundBlockQuote,
                    line: range.lowerBound.line,
                    column: 1,
                    message: "Block quote should be preceded by a blank line",
                    fix: analysis.nsInsertionRange(at: lineOffsets[range.lowerBound.line])
                        .map { LintFix(range: $0, replacement: "\n") }
                ))
            }
        }
        let endLineIdx = range.upperBound.line - 1
        let nextLineIdx = endLineIdx + 1
        if nextLineIdx < lines.count, nextLineIdx >= 0 {
            let nextLine = lines[nextLineIdx]
            if !nextLine.allSatisfy(\.isWhitespace) {
                let insertUTF8 = lineOffsets[range.upperBound.line] + (range.upperBound.column - 1)
                violations.append(LintViolation(
                    rule: .blankLineAroundBlockQuote,
                    line: range.upperBound.line,
                    column: range.upperBound.column,
                    message: "Block quote should be followed by a blank line",
                    fix: analysis.nsInsertionRange(at: insertUTF8)
                        .map { LintFix(range: $0, replacement: "\n") }
                ))
            }
        }

        descendInto(blockQuote)
    }

    // MARK: Lists

    mutating func visitUnorderedList(_ list: UnorderedList) {
        for item in list.listItems {
            guard let range = item.range else { continue }
            let lineIdx = range.lowerBound.line - 1
            guard lineIdx >= 0, lineIdx < lines.count else { continue }
            let rawLine = lines[lineIdx]
            let trimmed = rawLine.drop(while: \.isWhitespace)
            if let marker = trimmed.first, (marker == "-" || marker == "*" || marker == "+") {
                listMarkers.append((marker, range.lowerBound.line))
            }
        }
        descendInto(list)
    }

    // Called after the full walk to produce consistent-list-marker violations.
    // Since MarkupWalker doesn't have a post-visit hook, we trigger this
    // from the top-level Document visit.
    mutating func visitDocument(_ document: Document) {
        descendInto(document)
        checkConsistentListMarkers()
    }

    private mutating func checkConsistentListMarkers() {
        guard !listMarkers.isEmpty else { return }
        // Prefer "-" as the standard marker
        let preferred: Character = "-"
        for (marker, line) in listMarkers where marker != preferred {
            let lineIdx = line - 1
            guard lineIdx >= 0, lineIdx < lines.count else { continue }
            let rawLine = lines[lineIdx]
            let leadingSpaces = rawLine.prefix(while: \.isWhitespace).utf8.count
            let utf8Start = line < lineOffsets.count ? lineOffsets[line] + leadingSpaces : 0
            let utf8End = utf8Start + 1 // single-byte ASCII marker character
            violations.append(LintViolation(
                rule: .consistentListMarker,
                line: line,
                column: rawLine.prefix(while: \.isWhitespace).count + 1,
                message: "Expected list marker '-' but found '\(marker)'",
                fix: analysis.nsRange(utf8Start: utf8Start, utf8End: utf8End)
                    .map { LintFix(range: $0, replacement: "-") }
            ))
        }
    }
}

// MARK: - String helper

private extension String {
    /// Split into lines preserving the count (empty trailing line included if text ends with newline).
    func splitLines() -> [String] {
        var result: [String] = []
        var current = ""
        for char in self {
            if char == "\n" {
                result.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current)
        return result
    }
}
