import XCTest
@testable import MarkView

final class MarkdownLinterTests: XCTestCase {

    // MARK: - atxHeadingSpace

    func testAtxHeadingSpaceDetectsNoSpace() async {
        let violations = await MarkdownLinter.lint("#Heading\n")
        XCTAssertTrue(violations.contains { $0.rule == .atxHeadingSpace })
    }

    func testAtxHeadingSpacePassesWithSpace() async {
        let violations = await MarkdownLinter.lint("# Heading\n")
        XCTAssertFalse(violations.contains { $0.rule == .atxHeadingSpace })
    }

    func testAtxHeadingSpaceFix() async {
        let text = "#Heading\n"
        let violations = await MarkdownLinter.lint(text)
        let fixed = MarkdownLinter.applyFixes(to: text, violations: violations)
        XCTAssertTrue(fixed.contains("# Heading") || fixed.contains("# "))
    }

    // MARK: - blankLineAroundHeading

    func testBlankLineAroundHeadingDetectsMissingBefore() async {
        let text = "Some text\n# Heading\n"
        let violations = await MarkdownLinter.lint(text)
        let relevant = violations.filter { $0.rule == .blankLineAroundHeading }
        XCTAssertTrue(relevant.contains { $0.message.contains("preceded") })
    }

    func testBlankLineAroundHeadingViolationIsOnHeadingLine() async {
        // Regression: heading without blank line after it must report the
        // violation on the heading line itself, not on text further down.
        let text = "## Heading\nParagraph text\n- list item\n"
        let violations = await MarkdownLinter.lint(text)
        let followed = violations.filter {
            $0.rule == .blankLineAroundHeading && $0.message.contains("followed")
        }
        XCTAssertEqual(followed.count, 1)
        // Violation must be on line 1 (the heading), not line 2 or later
        XCTAssertEqual(followed.first?.line, 1)
    }

    func testBlankLineAroundHeadingPassesWithBlanks() async {
        let text = "Some text\n\n# Heading\n\nMore text\n"
        let violations = await MarkdownLinter.lint(text)
        let relevant = violations.filter { $0.rule == .blankLineAroundHeading }
        XCTAssertEqual(relevant.count, 0)
    }

    // MARK: - headingHierarchy

    func testHeadingHierarchyDetectsSkip() async {
        let text = "# H1\n\n### H3\n"
        let violations = await MarkdownLinter.lint(text)
        XCTAssertTrue(violations.contains { $0.rule == .headingHierarchy })
    }

    func testHeadingHierarchyPassesSequential() async {
        let text = "# H1\n\n## H2\n\n### H3\n"
        let violations = await MarkdownLinter.lint(text)
        XCTAssertFalse(violations.contains { $0.rule == .headingHierarchy })
    }

    func testHeadingHierarchyNotFixable() async {
        let text = "# H1\n\n### H3\n"
        let violations = await MarkdownLinter.lint(text)
        let relevant = violations.filter { $0.rule == .headingHierarchy }
        XCTAssertTrue(relevant.allSatisfy { $0.fix == nil })
    }

    // MARK: - trailingWhitespace

    func testTrailingWhitespaceDetected() async {
        let text = "Hello   \nWorld\n"
        let violations = await MarkdownLinter.lint(text)
        XCTAssertTrue(violations.contains { $0.rule == .trailingWhitespace })
    }

    func testTrailingWhitespaceAllowsTwoSpaces() async {
        let text = "Hello  \nWorld\n"
        let violations = await MarkdownLinter.lint(text)
        XCTAssertFalse(violations.contains { $0.rule == .trailingWhitespace })
    }

    func testTrailingWhitespaceFix() async {
        let text = "Hello   \nWorld\n"
        let violations = await MarkdownLinter.lint(text)
        let fixed = MarkdownLinter.applyFixes(to: text, violations: violations)
        XCTAssertFalse(fixed.contains("   "))
    }

    // MARK: - consecutiveBlankLines

    func testConsecutiveBlankLinesDetected() async {
        let text = "Hello\n\n\nWorld\n"
        let violations = await MarkdownLinter.lint(text)
        XCTAssertTrue(violations.contains { $0.rule == .consecutiveBlankLines })
    }

    func testConsecutiveBlankLinesPassesSingle() async {
        let text = "Hello\n\nWorld\n"
        let violations = await MarkdownLinter.lint(text)
        XCTAssertFalse(violations.contains { $0.rule == .consecutiveBlankLines })
    }

    // MARK: - noEmptyLinks

    func testNoEmptyLinksDetectsEmptyDestination() async {
        let text = "[text]()\n"
        let violations = await MarkdownLinter.lint(text)
        let relevant = violations.filter { $0.rule == .noEmptyLinks }
        XCTAssertTrue(relevant.contains { $0.message.contains("destination") })
    }

    func testNoEmptyLinksPassesValid() async {
        let text = "[text](https://example.com)\n"
        let violations = await MarkdownLinter.lint(text)
        XCTAssertFalse(violations.contains { $0.rule == .noEmptyLinks })
    }

    // MARK: - blankLineAroundCodeBlock

    func testBlankLineAroundCodeBlockDetectsMissing() async {
        let text = "Some text\n```\ncode\n```\nMore text\n"
        let violations = await MarkdownLinter.lint(text)
        let relevant = violations.filter { $0.rule == .blankLineAroundCodeBlock }
        XCTAssertFalse(relevant.isEmpty)
    }

    func testBlankLineAroundCodeBlockPassesWithBlanks() async {
        let text = "Some text\n\n```\ncode\n```\n\nMore text\n"
        let violations = await MarkdownLinter.lint(text)
        let relevant = violations.filter { $0.rule == .blankLineAroundCodeBlock }
        XCTAssertEqual(relevant.count, 0)
    }

    // MARK: - blankLineAroundBlockQuote

    func testBlankLineAroundBlockQuoteDetectsMissing() async {
        let text = "Some text\n> quoted\nMore text\n"
        let violations = await MarkdownLinter.lint(text)
        let relevant = violations.filter { $0.rule == .blankLineAroundBlockQuote }
        XCTAssertFalse(relevant.isEmpty)
    }

    // MARK: - consistentListMarker

    func testConsistentListMarkerDetectsMixed() async {
        let text = "- item one\n* item two\n+ item three\n"
        let violations = await MarkdownLinter.lint(text)
        let relevant = violations.filter { $0.rule == .consistentListMarker }
        // '*' and '+' should be flagged; '-' is preferred
        XCTAssertEqual(relevant.count, 2)
    }

    func testConsistentListMarkerPassesUniform() async {
        let text = "- item one\n- item two\n- item three\n"
        let violations = await MarkdownLinter.lint(text)
        XCTAssertFalse(violations.contains { $0.rule == .consistentListMarker })
    }

    func testConsistentListMarkerFix() async {
        let text = "* item one\n* item two\n"
        let violations = await MarkdownLinter.lint(text)
        let fixed = MarkdownLinter.applyFixes(to: text, violations: violations)
        XCTAssertTrue(fixed.hasPrefix("- item one"))
    }

    // MARK: - noTrailingHashHeading

    func testNoTrailingHashHeadingDetected() async {
        let text = "# Heading #\n"
        let violations = await MarkdownLinter.lint(text)
        XCTAssertTrue(violations.contains { $0.rule == .noTrailingHashHeading })
    }

    func testNoTrailingHashHeadingPassesClean() async {
        let text = "# Heading\n"
        let violations = await MarkdownLinter.lint(text)
        XCTAssertFalse(violations.contains { $0.rule == .noTrailingHashHeading })
    }

    // MARK: - applyFixes

    func testApplyFixesReverseOrder() async {
        let text = "* one\n* two\n"
        let violations = await MarkdownLinter.lint(text)
        let fixed = MarkdownLinter.applyFixes(to: text, violations: violations)
        XCTAssertEqual(fixed, "- one\n- two\n")
    }

    func testApplyFixesNoOp() async {
        let text = "# Heading\n\nSome paragraph.\n"
        let violations = await MarkdownLinter.lint(text)
        let fixable = violations.filter { $0.fix != nil }
        if fixable.isEmpty {
            let fixed = MarkdownLinter.applyFixes(to: text, violations: violations)
            XCTAssertEqual(fixed, text)
        }
    }

    // MARK: - Line number accuracy

    func testLineNumbersMatchActualLines() async {
        // Realistic document with known violations at specific lines
        let text = [
            "# Title",           // line 1
            "",                  // line 2
            "Some paragraph.",   // line 3
            "## Section",        // line 4 — missing blank line before heading
            "",                  // line 5
            "Hello   ",          // line 6 — trailing whitespace (3 spaces)
            "",                  // line 7
            "* item one",        // line 8 — wrong list marker
            "- item two",        // line 9
            "",                  // line 10
            "### Deep",          // line 11 — heading hierarchy skip (h2 → h3 is fine, but let's keep it)
            "",                  // line 12
            "[text]()",          // line 13 — empty link destination
            "",                  // line 14
        ].joined(separator: "\n")

        let violations = await MarkdownLinter.lint(text)

        // Check specific violations and their line numbers
        let blankAround = violations.filter { $0.rule == .blankLineAroundHeading }
        let trailingWS = violations.filter { $0.rule == .trailingWhitespace }
        let listMarker = violations.filter { $0.rule == .consistentListMarker }
        let emptyLink = violations.filter { $0.rule == .noEmptyLinks }

        // "## Section" on line 4 should have blank-line-around-heading violation
        XCTAssertTrue(blankAround.contains { $0.line == 4 },
            "Expected blank-line-around-heading on line 4, got lines: \(blankAround.map(\.line))")

        // Trailing whitespace on line 6
        XCTAssertTrue(trailingWS.contains { $0.line == 6 },
            "Expected trailing-whitespace on line 6, got lines: \(trailingWS.map(\.line))")

        // Wrong list marker on line 8
        XCTAssertTrue(listMarker.contains { $0.line == 8 },
            "Expected consistent-list-marker on line 8, got lines: \(listMarker.map(\.line))")

        // Empty link on line 13
        XCTAssertTrue(emptyLink.contains { $0.line == 13 },
            "Expected no-empty-links on line 13, got lines: \(emptyLink.map(\.line))")
    }

    // MARK: - Clean document

    func testCleanDocumentHasNoViolations() async {
        let text = """
        # Title

        Some paragraph text.

        ## Section

        - item one
        - item two

        > A quote

        ```
        code block
        ```

        [Link](https://example.com)
        """
        let violations = await MarkdownLinter.lint(text)
        XCTAssertEqual(violations.count, 0, "Clean document should have 0 violations, got: \(violations.map { "\($0.rule.displayName): \($0.message) (line \($0.line))" })")
    }
}
