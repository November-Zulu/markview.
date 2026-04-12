import XCTest
import Markdown
@testable import MarkView

final class MarkdownParserTests: XCTestCase {

    func testParsesHeadingLevels() async {
        let doc = await MarkdownParser.parse("""
        # One
        ## Two
        ### Three
        """)
        let headings = doc.children.compactMap { $0 as? Heading }
        XCTAssertEqual(headings.map(\.level), [1, 2, 3])
    }

    func testParsesParagraphWithBoldAndItalic() async {
        let doc = await MarkdownParser.parse("This is **bold** and *italic*.")
        let paragraphs = doc.children.compactMap { $0 as? Paragraph }
        XCTAssertEqual(paragraphs.count, 1)

        let children = Array(paragraphs[0].children)
        XCTAssertTrue(children.contains { $0 is Strong })
        XCTAssertTrue(children.contains { $0 is Emphasis })
    }

    func testParsesUnorderedList() async {
        let doc = await MarkdownParser.parse("""
        - one
        - two
        - three
        """)
        let lists = doc.children.compactMap { $0 as? UnorderedList }
        XCTAssertEqual(lists.count, 1)
        XCTAssertEqual(Array(lists[0].listItems).count, 3)
    }

    func testParsesOrderedList() async {
        let doc = await MarkdownParser.parse("""
        1. first
        2. second
        """)
        let lists = doc.children.compactMap { $0 as? OrderedList }
        XCTAssertEqual(lists.count, 1)
        XCTAssertEqual(Array(lists[0].listItems).count, 2)
    }

    func testParsesCodeBlock() async {
        let doc = await MarkdownParser.parse("""
        ```
        let x = 1
        ```
        """)
        let codeBlocks = doc.children.compactMap { $0 as? CodeBlock }
        XCTAssertEqual(codeBlocks.count, 1)
        XCTAssertTrue(codeBlocks[0].code.contains("let x = 1"))
    }

    func testParsesBlockQuote() async {
        let doc = await MarkdownParser.parse("> quoted text")
        let quotes = doc.children.compactMap { $0 as? BlockQuote }
        XCTAssertEqual(quotes.count, 1)
    }

    func testParsesLink() async {
        let doc = await MarkdownParser.parse("An [example](https://example.com) link.")
        let paragraphs = doc.children.compactMap { $0 as? Paragraph }
        XCTAssertEqual(paragraphs.count, 1)

        let links = Array(paragraphs[0].children).compactMap { $0 as? Markdown.Link }
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[0].destination, "https://example.com")
    }

    func testParsesInlineCode() async {
        let doc = await MarkdownParser.parse("Use `print()` to output.")
        let paragraphs = doc.children.compactMap { $0 as? Paragraph }
        XCTAssertEqual(paragraphs.count, 1)

        let codes = Array(paragraphs[0].children).compactMap { $0 as? InlineCode }
        XCTAssertEqual(codes.count, 1)
        XCTAssertEqual(codes[0].code, "print()")
    }

    func testEmptyStringParsesToEmptyDocument() async {
        let doc = await MarkdownParser.parse("")
        XCTAssertEqual(Array(doc.children).count, 0)
    }
}
