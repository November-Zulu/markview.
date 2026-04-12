import SwiftUI
import AppKit

/// SwiftUI-wrapped `NSTextView` configured for Markdown editing:
/// monospaced font, line wrapping, undo/redo, no smart substitutions.
struct MarkdownTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var scrollFraction: CGFloat
    var syntaxHighlightingEnabled: Bool = true
    var editorLightModeEnabled: Bool = false

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
        textView.delegate = context.coordinator
        context.coordinator.textView = textView

        // Initial content without triggering a change notification.
        textView.string = text
        textView.undoManager?.removeAllActions()

        if syntaxHighlightingEnabled {
            context.coordinator.scheduleHighlight()
        }

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
                coordinator.scheduleHighlight()
            } else {
                coordinator.clearHighlighting()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, scrollFraction: $scrollFraction, syntaxHighlightingEnabled: syntaxHighlightingEnabled)
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
        weak var textView: NSTextView?
        var isApplyingUserEdit = false
        var lastSyntaxHighlightingEnabled: Bool
        var lastEditorLightModeEnabled: Bool = false
        private var highlightTask: Task<Void, Never>?

        init(text: Binding<String>, scrollFraction: Binding<CGFloat>, syntaxHighlightingEnabled: Bool) {
            self.text = text
            self.scrollFraction = scrollFraction
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
        }

        func scheduleHighlight() {
            highlightTask?.cancel()
            highlightTask = Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(200))
                guard !Task.isCancelled else { return }
                guard let self, let textView = self.textView else { return }

                let source = textView.string
                let highlights = await MarkdownHighlighter.highlights(for: source)
                guard !Task.isCancelled else { return }
                guard let storage = textView.textStorage else { return }

                // Verify text hasn't changed while we were computing
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
                storage.endEditing()

                textView.selectedRanges = selectedRanges
            }
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
    }
}
