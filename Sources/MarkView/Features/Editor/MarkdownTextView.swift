import SwiftUI
import AppKit

/// SwiftUI-wrapped `NSTextView` configured for Markdown editing:
/// monospaced font, line wrapping, undo/redo, no smart substitutions.
struct MarkdownTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var scrollFraction: CGFloat
    @Binding var lintViolations: [LintViolation]
    @Binding var lintSourceHash: Int?
    /// Set to a line number to scroll the editor there, then reset to nil.
    @Binding var scrollToLine: Int?
    var syntaxHighlightingEnabled: Bool = true
    var editorLightModeEnabled: Bool = false
    var lineNumbersEnabled: Bool = false

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = true
        scrollView.autohidesScrollers = false
        scrollView.borderType = .noBorder

        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        configure(textView)
        applyAppearance(textView)

        // Set initial content before attaching the delegate so that
        // the programmatic string assignment cannot trigger textDidChange.
        textView.string = text
        textView.undoManager?.removeAllActions()

        textView.delegate = context.coordinator
        context.coordinator.textView = textView

        if syntaxHighlightingEnabled {
            context.coordinator.applyHighlightImmediately()
        }
        context.coordinator.lintImmediately()

        // Line number gutter — always create ruler, toggle visibility as needed.
        // Creating the ruler during updateNSView disrupts NSScrollView tiling.
        let rulerView = LineNumberRulerView(textView: textView)
        scrollView.hasVerticalRuler = true
        scrollView.verticalRulerView = rulerView
        scrollView.rulersVisible = lineNumbersEnabled

        // Observe scroll position changes
        scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.scrollViewDidScroll(_:)),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        guard !context.coordinator.isApplyingUserEdit else { return }

        let coordinator = context.coordinator
        let highlightingChanged = coordinator.lastSyntaxHighlightingEnabled != syntaxHighlightingEnabled
        let appearanceChanged = coordinator.lastEditorLightModeEnabled != editorLightModeEnabled

        coordinator.lastSyntaxHighlightingEnabled = syntaxHighlightingEnabled
        coordinator.lastEditorLightModeEnabled = editorLightModeEnabled

        var textChanged = false
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
            textChanged = true
        }

        if appearanceChanged {
            applyAppearance(textView)
        }

        if highlightingChanged || (textChanged && syntaxHighlightingEnabled) {
            if syntaxHighlightingEnabled {
                // Programmatic text changes get immediate highlighting (no debounce)
                // to prevent SwiftUI update cycles from wiping applied attributes.
                coordinator.applyHighlightImmediately()
            } else {
                coordinator.clearHighlighting()
            }
        }

        if textChanged {
            coordinator.lintImmediately()
        }

        if let line = scrollToLine {
            coordinator.scrollToLine(line)
            DispatchQueue.main.async { self.scrollToLine = nil }
        }

        // Toggle line number gutter visibility
        scrollView.rulersVisible = lineNumbersEnabled
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            text: $text,
            scrollFraction: $scrollFraction,
            lintViolations: $lintViolations,
            lintSourceHash: $lintSourceHash,
            syntaxHighlightingEnabled: syntaxHighlightingEnabled
        )
    }

    // MARK: - Configuration

    private func configure(_ textView: NSTextView) {
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        textView.usesFontPanel = false

        // Markdown authors need literal characters — disable "helpful" substitutions.
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.smartInsertDeleteEnabled = false

        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = .labelColor
        textView.insertionPointColor = .labelColor
        textView.drawsBackground = true
        textView.textContainerInset = NSSize(width: 16, height: 16)

        // Line wrapping
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: 0,
            height: CGFloat.greatestFiniteMagnitude
        )
    }

    private func applyAppearance(_ textView: NSTextView) {
        if editorLightModeEnabled {
            textView.appearance = NSAppearance(named: .aqua)
            textView.backgroundColor = .white
            textView.textColor = .black
            textView.insertionPointColor = .black
        } else {
            textView.appearance = nil // inherit system
            textView.backgroundColor = .textBackgroundColor
            textView.textColor = .labelColor
            textView.insertionPointColor = .labelColor
        }
        // Also update the enclosing scroll view
        if let scrollView = textView.enclosingScrollView {
            scrollView.backgroundColor = textView.backgroundColor
        }
    }

    // MARK: - Coordinator

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>
        var scrollFraction: Binding<CGFloat>
        var lintViolations: Binding<[LintViolation]>
        var lintSourceHash: Binding<Int?>
        weak var textView: NSTextView?
        var isApplyingUserEdit = false
        var lastSyntaxHighlightingEnabled: Bool
        var lastEditorLightModeEnabled: Bool = false
        private var highlightTask: Task<Void, Never>?
        private var lintTask: Task<Void, Never>?

        init(
            text: Binding<String>,
            scrollFraction: Binding<CGFloat>,
            lintViolations: Binding<[LintViolation]>,
            lintSourceHash: Binding<Int?>,
            syntaxHighlightingEnabled: Bool
        ) {
            self.text = text
            self.scrollFraction = scrollFraction
            self.lintViolations = lintViolations
            self.lintSourceHash = lintSourceHash
            self.lastSyntaxHighlightingEnabled = syntaxHighlightingEnabled
        }

        @objc func scrollViewDidScroll(_ notification: Notification) {
            guard let clipView = notification.object as? NSClipView,
                  let documentView = clipView.documentView else { return }
            let contentHeight = documentView.frame.height
            let visibleHeight = clipView.bounds.height
            let scrollableHeight = contentHeight - visibleHeight
            guard scrollableHeight > 0 else {
                scrollFraction.wrappedValue = 0
                return
            }
            scrollFraction.wrappedValue = min(1, max(0, clipView.bounds.origin.y / scrollableHeight))
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            isApplyingUserEdit = true
            text.wrappedValue = textView.string
            isApplyingUserEdit = false

            if lastSyntaxHighlightingEnabled {
                scheduleHighlight()
            }
            scheduleLint()
        }

        /// Highlights immediately (no debounce). Used for initial load and
        /// programmatic text changes where the text is already stable.
        func applyHighlightImmediately() {
            highlightTask?.cancel()
            highlightTask = Task { [weak self] in
                guard let self, let textView = self.textView else { return }
                let source = textView.string
                let highlights = await MarkdownHighlighter.highlights(for: source)
                guard !Task.isCancelled else { return }
                self.applyHighlights(highlights, for: source)
            }
        }

        /// Highlights after a debounce delay. Used for user typing.
        func scheduleHighlight() {
            highlightTask?.cancel()
            highlightTask = Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(200))
                guard !Task.isCancelled else { return }
                guard let self, let textView = self.textView else { return }
                let source = textView.string
                let highlights = await MarkdownHighlighter.highlights(for: source)
                guard !Task.isCancelled else { return }
                self.applyHighlights(highlights, for: source)
            }
        }

        private func applyHighlights(_ highlights: [MarkdownHighlighter.Highlight], for source: String) {
            guard let textView, let storage = textView.textStorage else { return }
            guard textView.string == source else { return }

            let fullRange = NSRange(location: 0, length: storage.length)
            let selectedRanges = textView.selectedRanges

            storage.beginEditing()
            storage.setAttributes(MarkdownHighlighter.baseAttributes, range: fullRange)
            for highlight in highlights {
                guard highlight.range.location + highlight.range.length <= storage.length else {
                    continue
                }
                storage.addAttributes(highlight.attributes, range: highlight.range)
            }
            // Re-apply lint underlines so they survive highlight resets
            for violation in lintViolations.wrappedValue {
                guard let range = violation.underlineRange,
                      range.location + range.length <= storage.length else { continue }
                storage.addAttributes([
                    .underlineStyle: NSUnderlineStyle.patternDot.rawValue | NSUnderlineStyle.single.rawValue,
                    .underlineColor: DesignTokens.LinterColors.warning,
                ], range: range)
            }
            storage.endEditing()

            textView.selectedRanges = selectedRanges
        }

        func clearHighlighting() {
            highlightTask?.cancel()
            guard let textView, let storage = textView.textStorage else { return }
            let selectedRanges = textView.selectedRanges
            let fullRange = NSRange(location: 0, length: storage.length)
            storage.beginEditing()
            storage.setAttributes(MarkdownHighlighter.baseAttributes, range: fullRange)
            storage.endEditing()
            textView.selectedRanges = selectedRanges
        }

        // MARK: - Linting

        func lintImmediately() {
            lintTask?.cancel()
            lintTask = Task { [weak self] in
                guard let self, let textView = self.textView else { return }
                let source = textView.string
                let violations = await MarkdownLinter.lint(source)
                guard !Task.isCancelled else { return }
                self.lintViolations.wrappedValue = violations
                self.lintSourceHash.wrappedValue = source.hashValue
                self.applyLintUnderlines(violations, for: source)
            }
        }

        func scheduleLint() {
            lintTask?.cancel()
            lintTask = Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(250))
                guard !Task.isCancelled else { return }
                guard let self, let textView = self.textView else { return }
                let source = textView.string
                let violations = await MarkdownLinter.lint(source)
                guard !Task.isCancelled else { return }
                self.lintViolations.wrappedValue = violations
                self.lintSourceHash.wrappedValue = source.hashValue
                self.applyLintUnderlines(violations, for: source)
            }
        }

        /// Applies dotted underlines at violation locations in the text storage.
        private func applyLintUnderlines(_ violations: [LintViolation], for source: String) {
            guard let textView, let storage = textView.textStorage else { return }
            guard textView.string == source else { return }
            guard !violations.isEmpty else { return }

            let selectedRanges = textView.selectedRanges
            storage.beginEditing()
            for violation in violations {
                guard let range = violation.underlineRange,
                      range.location + range.length <= storage.length else { continue }
                storage.addAttributes([
                    .underlineStyle: NSUnderlineStyle.patternDot.rawValue | NSUnderlineStyle.single.rawValue,
                    .underlineColor: DesignTokens.LinterColors.warning,
                ], range: range)
            }
            storage.endEditing()
            textView.selectedRanges = selectedRanges
        }

        // MARK: - Scroll to line

        func scrollToLine(_ lineNumber: Int) {
            guard let textView else { return }
            let text = textView.string
            let lineOffsets = MarkdownHighlighter.buildLineOffsets(text)
            guard lineNumber >= 1, lineNumber < lineOffsets.count else { return }
            let location = lineOffsets[lineNumber]
            let range = NSRange(location: location, length: 0)
            textView.setSelectedRange(range)
            textView.scrollRangeToVisible(range)
        }
    }
}
