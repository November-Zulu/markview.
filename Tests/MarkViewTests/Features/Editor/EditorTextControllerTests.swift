import XCTest
import AppKit
@testable import MarkView

@MainActor
final class EditorTextControllerTests: XCTestCase {

    private func makeState(
        text: String = "",
        syntaxHighlightingEnabled: Bool = false,
        editorLightModeEnabled: Bool = false,
        lineNumbersEnabled: Bool = false,
        lintViolations: [LintViolation] = [],
        pendingScrollToLine: Int? = nil
    ) -> EditorTextState {
        EditorTextState(
            text: text,
            syntaxHighlightingEnabled: syntaxHighlightingEnabled,
            editorLightModeEnabled: editorLightModeEnabled,
            lineNumbersEnabled: lineNumbersEnabled,
            lintViolations: lintViolations,
            pendingScrollToLine: pendingScrollToLine
        )
    }

    private func textView(of controller: EditorTextController) -> NSTextView {
        guard let tv = controller.scrollView.documentView as? NSTextView else {
            fatalError("controller.scrollView.documentView is not NSTextView")
        }
        return tv
    }

    // MARK: - Programmatic text change (autofix, file load)

    func testApplyWithChangedTextRefreshesLint() async {
        let controller = EditorTextController()
        var lintResults: [(Int, [LintViolation])] = []
        controller.onLintResult = { lintResults.append(($0, $1)) }

        // Stage 1: dirty text with an old violation passed in.
        let staleViolation = LintViolation(
            rule: .trailingWhitespace,
            line: 1,
            column: 1,
            message: "stale",
            fix: nil,
            underlineRange: NSRange(location: 0, length: 5)
        )
        await controller.apply(makeState(
            text: "dirty  ",
            lintViolations: [staleViolation]
        )).value

        // Stage 2: caller swapped in clean text but still passes the stale
        // violation (mirrors the autofix flow where document.content updates
        // before the violations binding gets refreshed).
        await controller.apply(makeState(
            text: "clean",
            lintViolations: [staleViolation]
        )).value

        // Wait briefly for the controller's re-lint task to deliver.
        for _ in 0..<10 where lintResults.last?.1.isEmpty != true {
            try? await Task.sleep(for: .milliseconds(50))
        }

        XCTAssertEqual(
            lintResults.last?.1.count, 0,
            "controller should re-lint after programmatic text change and emit fresh empty violations"
        )
    }

    // MARK: - User editing

    func testUserEditFiresOnTextChange() async {
        let controller = EditorTextController()
        var receivedTexts: [String] = []
        controller.onTextChange = { receivedTexts.append($0) }

        await controller.apply(makeState(text: "old")).value

        let tv = textView(of: controller)
        tv.string = "new"
        let notification = Notification(name: NSText.didChangeNotification, object: tv)
        controller.textDidChange(notification)

        XCTAssertEqual(receivedTexts, ["new"])
    }

    // MARK: - Idempotency

    func testApplyingSameStateTwiceIsNoOp() async {
        let controller = EditorTextController()
        let state = makeState(text: "# Hello", syntaxHighlightingEnabled: true)

        await controller.apply(state).value

        // Clobber the heading color with a sentinel; if the second apply is a
        // no-op, the sentinel survives.
        let storage = textView(of: controller).textStorage!
        storage.addAttribute(
            .foregroundColor,
            value: NSColor.red,
            range: NSRange(location: 0, length: 7)
        )

        await controller.apply(state).value

        let color = storage.attributes(at: 0, effectiveRange: nil)[.foregroundColor] as? NSColor
        XCTAssertEqual(color, NSColor.red, "second apply with same state should not redraw")
    }

    // MARK: - Tracer

    func testApplySetsTextInStorage() async {
        let controller = EditorTextController()

        await controller.apply(makeState(text: "# hi")).value

        XCTAssertEqual(textView(of: controller).string, "# hi")
    }

    // MARK: - Highlighting

    func testHighlightingOnAppliesHeadingColor() async {
        let controller = EditorTextController()

        await controller.apply(makeState(
            text: "# Heading",
            syntaxHighlightingEnabled: true
        )).value

        let storage = textView(of: controller).textStorage!
        let attrs = storage.attributes(at: 0, effectiveRange: nil)
        let color = attrs[.foregroundColor] as? NSColor
        XCTAssertEqual(color, DesignTokens.SyntaxColors.heading1)
    }

    // MARK: - Scroll to line

    func testScrollToLineMovesCursorAndReportsHandled() async {
        let controller = EditorTextController()
        var handledCount = 0
        controller.onScrollToLineHandled = { handledCount += 1 }

        let text = "line 1\nline 2\nline 3"
        await controller.apply(makeState(
            text: text,
            pendingScrollToLine: 3
        )).value

        let tv = textView(of: controller)
        let line3Offset = (text as NSString).range(of: "line 3").location
        XCTAssertEqual(tv.selectedRange().location, line3Offset)
        XCTAssertEqual(handledCount, 1)
    }

    func testScrollToLineNilDoesNotFireHandler() async {
        let controller = EditorTextController()
        var handledCount = 0
        controller.onScrollToLineHandled = { handledCount += 1 }

        await controller.apply(makeState(text: "hello", pendingScrollToLine: nil)).value

        XCTAssertEqual(handledCount, 0)
    }

    // MARK: - Appearance

    func testLightModeSetsWhiteBackground() async {
        let controller = EditorTextController()

        await controller.apply(makeState(
            text: "hello",
            editorLightModeEnabled: true
        )).value

        XCTAssertEqual(textView(of: controller).backgroundColor, .white)
        XCTAssertEqual(textView(of: controller).appearance?.name, .aqua)
    }

    // MARK: - Line numbers

    func testLineNumbersOffHidesGutter() async {
        let controller = EditorTextController()

        await controller.apply(makeState(lineNumbersEnabled: false)).value

        XCTAssertTrue(controller.gutter.isHidden)
    }

    func testLineNumbersOnShowsGutter() async {
        let controller = EditorTextController()

        await controller.apply(makeState(lineNumbersEnabled: true)).value

        XCTAssertFalse(controller.gutter.isHidden)
    }

    // MARK: - Linting

    func testLintViolationAppliesDottedUnderline() async {
        let controller = EditorTextController()
        let text = "Hello world"
        let violation = LintViolation(
            rule: .trailingWhitespace,
            line: 1,
            column: 1,
            message: "test",
            fix: nil,
            underlineRange: NSRange(location: 0, length: 5)
        )

        await controller.apply(makeState(
            text: text,
            lintViolations: [violation]
        )).value

        let storage = textView(of: controller).textStorage!
        let attrs = storage.attributes(at: 0, effectiveRange: nil)
        let style = attrs[.underlineStyle] as? Int
        let expected = NSUnderlineStyle.patternDot.rawValue | NSUnderlineStyle.single.rawValue
        XCTAssertEqual(style, expected)
    }

    func testHighlightAndLintComposeAtomically() async {
        let controller = EditorTextController()
        let text = "# Heading"
        let violation = LintViolation(
            rule: .trailingWhitespace,
            line: 1,
            column: 1,
            message: "test",
            fix: nil,
            underlineRange: NSRange(location: 0, length: text.utf16.count)
        )

        await controller.apply(makeState(
            text: text,
            syntaxHighlightingEnabled: true,
            lintViolations: [violation]
        )).value

        let storage = textView(of: controller).textStorage!
        let attrs = storage.attributes(at: 0, effectiveRange: nil)
        XCTAssertEqual(
            attrs[.foregroundColor] as? NSColor,
            DesignTokens.SyntaxColors.heading1,
            "heading color should survive lint underline pass"
        )
        let expectedStyle = NSUnderlineStyle.patternDot.rawValue | NSUnderlineStyle.single.rawValue
        XCTAssertEqual(
            attrs[.underlineStyle] as? Int,
            expectedStyle,
            "lint underline should survive highlight pass"
        )
    }

    func testHighlightingOffClearsHeadingColor() async {
        let controller = EditorTextController()

        await controller.apply(makeState(
            text: "# Heading",
            syntaxHighlightingEnabled: true
        )).value
        await controller.apply(makeState(
            text: "# Heading",
            syntaxHighlightingEnabled: false
        )).value

        let storage = textView(of: controller).textStorage!
        let attrs = storage.attributes(at: 0, effectiveRange: nil)
        let color = attrs[.foregroundColor] as? NSColor
        XCTAssertEqual(color, NSColor.labelColor)
    }
}
