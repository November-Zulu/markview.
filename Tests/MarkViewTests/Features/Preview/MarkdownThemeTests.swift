import XCTest
import SwiftUI
import AppKit
import Markdown
@testable import MarkView

final class MarkdownThemeTests: XCTestCase {

    // MARK: - Tracer

    func testDefaultThemeHasSensibleValues() {
        let theme = MarkdownTheme.default

        XCTAssertEqual(theme.headingSizes.count, 6, "expected 6 heading sizes (h1..h6)")
        XCTAssertGreaterThan(theme.bodyFontSize, 0)
        XCTAssertGreaterThan(theme.codeFontSize, 0)
    }

    // MARK: - headingSize lookup

    func testHeadingSizeReturnsCorrectEntryForLevel() {
        let theme = MarkdownTheme.default

        XCTAssertEqual(theme.headingSize(level: 3), theme.headingSizes[2])
    }

    func testHeadingSizeClampsAboveSix() {
        let theme = MarkdownTheme.default

        XCTAssertEqual(theme.headingSize(level: 7), theme.headingSizes.last)
        XCTAssertEqual(theme.headingSize(level: 99), theme.headingSizes.last)
    }

    func testHeadingSizeClampsBelowOne() {
        let theme = MarkdownTheme.default

        XCTAssertEqual(theme.headingSize(level: 0), theme.headingSizes.first)
        XCTAssertEqual(theme.headingSize(level: -5), theme.headingSizes.first)
    }

    // MARK: - InlineRenderer integration

    func testInlineRendererUsesThemeLinkColor() async {
        let analysis = await MarkdownAnalysis.analyze("[text](https://example.com)")
        let paragraph = analysis.document.child(at: 0) as? Paragraph
        XCTAssertNotNil(paragraph, "expected first block to be a Paragraph")

        var theme = MarkdownTheme.default
        theme.linkColor = .red
        let renderer = InlineRenderer(theme: theme)

        let attributed = renderer.attributedString(for: paragraph!)
        let firstRun = attributed.runs.first
        XCTAssertEqual(firstRun?.foregroundColor, NSColor(Color.red))
    }
}
