import XCTest
import Markdown
@testable import MarkView

final class MarkdownAnalysisTests: XCTestCase {

    // MARK: - Tracer

    func testAnalyzeReturnsSourceAndDocument() async {
        let analysis = await MarkdownAnalysis.analyze("# hi")

        XCTAssertEqual(analysis.source, "# hi")
        XCTAssertGreaterThan(analysis.document.childCount, 0)
    }

    // MARK: - Line offsets

    func testLineOffsetsForMultiLineText() async {
        let analysis = await MarkdownAnalysis.analyze("a\nb\nc")

        XCTAssertEqual(analysis.lineOffsets, [0, 0, 2, 4])
    }

    // MARK: - nsRange(for: markup)

    func testNSRangeForHeadingNode() async {
        let analysis = await MarkdownAnalysis.analyze("# Heading")
        let heading = analysis.document.child(at: 0) as? Heading
        XCTAssertNotNil(heading, "expected first child to be a Heading")

        let range = analysis.nsRange(for: heading!)

        XCTAssertEqual(range, NSRange(location: 0, length: 9))
    }

    // MARK: - nsRange(forLine:)

    func testNSRangeForLineCoversOnlyThatLine() async {
        let analysis = await MarkdownAnalysis.analyze("a\nb")

        let range = analysis.nsRange(forLine: 2)

        XCTAssertEqual(range, NSRange(location: 2, length: 1))
    }

    func testNSRangeForOutOfBoundsLineReturnsNil() async {
        let analysis = await MarkdownAnalysis.analyze("a\nb")

        XCTAssertNil(analysis.nsRange(forLine: 999))
        XCTAssertNil(analysis.nsRange(forLine: 0))
    }

    // MARK: - UTF-8 → NSRange conversion (critical multi-byte invariant)

    func testNSRangeForMultiByteUTF8Character() async {
        // "é" is 2 UTF-8 bytes (0xC3 0xA9) but 1 UTF-16 code unit.
        let analysis = await MarkdownAnalysis.analyze("é")

        let range = analysis.nsRange(utf8Start: 0, utf8End: 2)

        XCTAssertEqual(range, NSRange(location: 0, length: 1))
    }

    func testNSRangeForFourByteEmoji() async {
        // "🚀" is 4 UTF-8 bytes but 2 UTF-16 code units (surrogate pair).
        let analysis = await MarkdownAnalysis.analyze("🚀")

        let range = analysis.nsRange(utf8Start: 0, utf8End: 4)

        XCTAssertEqual(range, NSRange(location: 0, length: 2))
    }

    // MARK: - Insertion range

    func testNSInsertionRangeIsZeroLength() async {
        let analysis = await MarkdownAnalysis.analyze("hello")

        let range = analysis.nsInsertionRange(at: 3)

        XCTAssertEqual(range, NSRange(location: 3, length: 0))
    }

    // MARK: - Static fast path (no parsing)

    func testStaticLineOffsetsMatchesAnalyzeResult() async {
        let text = "a\nb\nc"

        let fast = MarkdownAnalysis.lineOffsets(of: text)
        let viaAnalyze = await MarkdownAnalysis.analyze(text).lineOffsets

        XCTAssertEqual(fast, [0, 0, 2, 4])
        XCTAssertEqual(fast, viaAnalyze)
    }
}
