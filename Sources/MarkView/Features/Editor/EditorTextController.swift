import AppKit

struct EditorTextState: Equatable {
    let text: String
    let syntaxHighlightingEnabled: Bool
    let editorLightModeEnabled: Bool
    let lineNumbersEnabled: Bool
    let lintViolations: [LintViolation]
    let pendingScrollToLine: Int?
}

@MainActor
final class EditorTextController: NSObject, NSTextViewDelegate {
    let scrollView: NSScrollView
    private let textView: NSTextView
    let gutter: LineNumberGutterView

    var onTextChange: ((String) -> Void)?
    var onScrollFraction: ((CGFloat) -> Void)?
    var onLintResult: ((Int, [LintViolation]) -> Void)?
    var onScrollToLineHandled: (() -> Void)?

    private var lastAppliedState: EditorTextState?
    private var redrawTask: Task<Void, Never>?
    private var lintTask: Task<Void, Never>?

    override init() {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = true
        scrollView.autohidesScrollers = false
        scrollView.borderType = .noBorder

        guard let textView = scrollView.documentView as? NSTextView else {
            fatalError("NSTextView.scrollableTextView did not produce an NSTextView")
        }
        self.scrollView = scrollView
        self.textView = textView
        self.gutter = LineNumberGutterView(textView: textView)
        super.init()

        Self.configure(textView)
        scrollView.addSubview(gutter)
        gutter.isHidden = true
        textView.delegate = self

        scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(scrollViewDidScroll(_:)),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )
    }

    // MARK: - NSTextViewDelegate

    nonisolated func textDidChange(_ notification: Notification) {
        MainActor.assumeIsolated {
            handleTextDidChange()
        }
    }

    private func handleTextDidChange() {
        let newText = textView.string
        onTextChange?(newText)
        scheduleLint(for: newText)
    }

    // MARK: - Scroll fraction

    @objc private func scrollViewDidScroll(_ notification: Notification) {
        guard let clipView = notification.object as? NSClipView,
              let documentView = clipView.documentView else { return }
        let contentHeight = documentView.frame.height
        let visibleHeight = clipView.bounds.height
        let scrollableHeight = contentHeight - visibleHeight
        let fraction: CGFloat
        if scrollableHeight <= 0 {
            fraction = 0
        } else {
            fraction = min(1, max(0, clipView.bounds.origin.y / scrollableHeight))
        }
        onScrollFraction?(fraction)
    }

    // MARK: - Apply

    @discardableResult
    func apply(_ state: EditorTextState) -> Task<Void, Never> {
        if state == lastAppliedState {
            return Task {}
        }
        let previousText = lastAppliedState?.text
        lastAppliedState = state
        if textView.string != state.text {
            let selectedRanges = textView.selectedRanges
            textView.string = state.text
            textView.selectedRanges = selectedRanges
        }
        if let previousText, previousText != state.text {
            // Programmatic text change (autofix, file load, tab switch).
            // NSTextView doesn't fire textDidChange for programmatic mutations,
            // so trigger a fresh lint here to keep violations in sync.
            lintImmediately(for: state.text)
        }
        applyAppearance(lightMode: state.editorLightModeEnabled)
        applyGutter(visible: state.lineNumbersEnabled)
        if let line = state.pendingScrollToLine {
            scrollToLine(line)
            onScrollToLineHandled?()
        }

        redrawTask?.cancel()
        let task: Task<Void, Never> = Task { [weak self] in
            await self?.redraw(for: state)
        }
        redrawTask = task
        return task
    }

    // MARK: - Initial content

    /// Sets the initial text without triggering textDidChange. Called once by
    /// the SwiftUI shell after construction so the undo stack starts clean.
    func loadInitialText(_ text: String) {
        textView.string = text
        textView.undoManager?.removeAllActions()
    }

    // MARK: - Private rendering

    private func redraw(for state: EditorTextState) async {
        if Task.isCancelled { return }
        let highlights: [MarkdownHighlighter.Highlight]
        if state.syntaxHighlightingEnabled {
            highlights = await MarkdownHighlighter.highlights(for: state.text)
        } else {
            highlights = []
        }
        if Task.isCancelled { return }
        applyDecorations(
            highlights: highlights,
            violations: state.lintViolations,
            expectedText: state.text
        )
    }

    private static let lintUnderlineStyle =
        NSUnderlineStyle.patternDot.rawValue | NSUnderlineStyle.single.rawValue

    private func applyDecorations(
        highlights: [MarkdownHighlighter.Highlight],
        violations: [LintViolation],
        expectedText: String
    ) {
        guard let storage = textView.textStorage else { return }
        guard textView.string == expectedText else { return }

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
        for violation in violations {
            guard let range = violation.underlineRange,
                  range.location + range.length <= storage.length else { continue }
            storage.addAttributes([
                .underlineStyle: Self.lintUnderlineStyle,
                .underlineColor: DesignTokens.LinterColors.warning,
            ], range: range)
        }
        storage.endEditing()

        textView.selectedRanges = selectedRanges
    }

    private func applyAppearance(lightMode: Bool) {
        if lightMode {
            textView.appearance = NSAppearance(named: .aqua)
            textView.backgroundColor = .white
            textView.textColor = .black
            textView.insertionPointColor = .black
        } else {
            textView.appearance = nil
            textView.backgroundColor = .textBackgroundColor
            textView.textColor = .labelColor
            textView.insertionPointColor = .labelColor
        }
        textView.enclosingScrollView?.backgroundColor = textView.backgroundColor
    }

    private func applyGutter(visible: Bool) {
        gutter.isHidden = !visible
        if visible {
            gutter.updateFrame()
            gutter.needsDisplay = true
        } else {
            textView.textContainerInset = NSSize(width: 16, height: 16)
        }
    }

    private func scrollToLine(_ lineNumber: Int) {
        let text = textView.string
        let lineOffsets = MarkdownAnalysis.lineOffsets(of: text)
        guard lineNumber >= 1, lineNumber < lineOffsets.count else { return }
        let utf8Offset = lineOffsets[lineNumber]
        // Convert UTF-8 byte offset to UTF-16-based NSRange location;
        // direct use would mis-position the cursor for multi-byte text.
        guard let range = MarkdownAnalysis.nsRange(
            utf8Start: utf8Offset, utf8End: utf8Offset, in: text
        ) else { return }
        textView.setSelectedRange(range)
        textView.scrollRangeToVisible(range)
    }

    // MARK: - Lint scheduling on user edit

    private func scheduleLint(for source: String) {
        lintTask?.cancel()
        lintTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(250))
            if Task.isCancelled { return }
            let violations = await MarkdownLinter.lint(source)
            if Task.isCancelled { return }
            self?.onLintResult?(source.hashValue, violations)
        }
    }

    private func lintImmediately(for source: String) {
        lintTask?.cancel()
        lintTask = Task { [weak self] in
            let violations = await MarkdownLinter.lint(source)
            if Task.isCancelled { return }
            self?.onLintResult?(source.hashValue, violations)
        }
    }

    // MARK: - Text view defaults

    private static func configure(_ textView: NSTextView) {
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        textView.usesFontPanel = false

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
}
