import XCTest
import Markdown
@testable import MarkView

/// Integration tests for swift-markdown via MarkdownAnalysis. Verify that
/// expected node types come out of the parser for representative inputs.
final class MarkdownParserTests: XCTestCase {

    func testParsesHeadingLevels() async {
        let doc = await MarkdownAnalysis.analyze("""
        # One
        ## Two
        ### Three
        """).document
        let headings = doc.children.compactMap { $0 as? Heading }
        XCTAssertEqual(headings.map(\.level), [1, 2, 3])
    }

    func testParsesParagraphWithBoldAndItalic() async {
        let doc = await MarkdownAnalysis.analyze("This is **bold** and *italic*.").document
        let paragraphs = doc.children.compactMap { $0 as? Paragraph }
        XCTAssertEqual(paragraphs.count, 1)

        let children = Array(paragraphs[0].children)
        XCTAssertTrue(children.contains { $0 is Strong })
        XCTAssertTrue(children.contains { $0 is Emphasis })
    }

    func testParsesUnorderedList() async {
        let doc = await MarkdownAnalysis.analyze("""
        - one
        - two
        - three
        """).document
        let lists = doc.children.compactMap { $0 as? UnorderedList }
        XCTAssertEqual(lists.count, 1)
        XCTAssertEqual(Array(lists[0].listItems).count, 3)
    }

    func testParsesOrderedList() async {
        let doc = await MarkdownAnalysis.analyze("""
        1. first
        2. second
        """).document
        let lists = doc.children.compactMap { $0 as? OrderedList }
        XCTAssertEqual(lists.count, 1)
        XCTAssertEqual(Array(lists[0].listItems).count, 2)
    }

    func testParsesCodeBlock() async {
        let doc = await MarkdownAnalysis.analyze("""
        ```
        let x = 1
        ```
        """).document
        let codeBlocks = doc.children.compactMap { $0 as? CodeBlock }
        XCTAssertEqual(codeBlocks.count, 1)
        XCTAssertTrue(codeBlocks[0].code.contains("let x = 1"))
    }

    func testParsesBlockQuote() async {
        let doc = await MarkdownAnalysis.analyze("> quoted text").document
        let quotes = doc.children.compactMap { $0 as? BlockQuote }
        XCTAssertEqual(quotes.count, 1)
    }

    func testParsesLink() async {
        let doc = await MarkdownAnalysis.analyze("An [example](https://example.com) link.").document
        let paragraphs = doc.children.compactMap { $0 as? Paragraph }
        XCTAssertEqual(paragraphs.count, 1)

        let links = Array(paragraphs[0].children).compactMap { $0 as? Markdown.Link }
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[0].destination, "https://example.com")
    }

    func testParsesInlineCode() async {
        let doc = await MarkdownAnalysis.analyze("Use `print()` to output.").document
        let paragraphs = doc.children.compactMap { $0 as? Paragraph }
        XCTAssertEqual(paragraphs.count, 1)

        let codes = Array(paragraphs[0].children).compactMap { $0 as? InlineCode }
        XCTAssertEqual(codes.count, 1)
        XCTAssertEqual(codes[0].code, "print()")
    }

    func testEmptyStringParsesToEmptyDocument() async {
        let doc = await MarkdownAnalysis.analyze("").document
        XCTAssertEqual(Array(doc.children).count, 0)
    }
}
