import SwiftUI
import AppKit

/// SwiftUI shell over `EditorTextController`. The controller owns the
/// `NSTextView`, gutter, and decoration logic; this view forwards state
/// in via `apply(state:)` and binds callbacks back to SwiftUI bindings.
struct MarkdownTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var scrollFraction: CGFloat
    @Binding var lintViolations: [LintViolation]
    @Binding var lintSourceHash: Int?
    @Binding var scrollToLine: Int?
    var syntaxHighlightingEnabled: Bool = true
    var editorLightModeEnabled: Bool = false
    var lineNumbersEnabled: Bool = false

    func makeNSView(context: Context) -> NSScrollView {
        let controller = context.coordinator
        controller.onTextChange = { [text = $text] newText in
            text.wrappedValue = newText
        }
        controller.onScrollFraction = { [scrollFraction = $scrollFraction] fraction in
            scrollFraction.wrappedValue = fraction
        }
        controller.onLintResult = { [lintViolations = $lintViolations, lintSourceHash = $lintSourceHash] hash, violations in
            lintViolations.wrappedValue = violations
            lintSourceHash.wrappedValue = hash
        }
        controller.onScrollToLineHandled = { [scrollToLine = $scrollToLine] in
            DispatchQueue.main.async { scrollToLine.wrappedValue = nil }
        }

        controller.loadInitialText(text)
        controller.apply(currentState())
        return controller.scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.apply(currentState())
    }

    func makeCoordinator() -> EditorTextController {
        EditorTextController()
    }

    private func currentState() -> EditorTextState {
        EditorTextState(
            text: text,
            syntaxHighlightingEnabled: syntaxHighlightingEnabled,
            editorLightModeEnabled: editorLightModeEnabled,
            lineNumbersEnabled: lineNumbersEnabled,
            lintViolations: lintViolations,
            pendingScrollToLine: scrollToLine
        )
    }
}
