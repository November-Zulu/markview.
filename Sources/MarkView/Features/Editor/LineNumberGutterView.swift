import AppKit

/// Draws line numbers in a gutter alongside an NSTextView.
/// Added as a floating subview of the NSScrollView (not the text view or
/// NSRulerView) to avoid both NSScrollView tiling issues and NSTextView
/// rendering interference.
final class LineNumberGutterView: NSView {

    private weak var textView: NSTextView?
    private let lineNumberFont = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
    private let textColor = NSColor.secondaryLabelColor

    static let defaultGutterWidth: CGFloat = 36

    init(textView: NSTextView) {
        self.textView = textView
        super.init(frame: .zero)

        NotificationCenter.default.addObserver(
            self, selector: #selector(handleChange(_:)),
            name: NSText.didChangeNotification, object: textView
        )
        if let clipView = textView.enclosingScrollView?.contentView {
            clipView.postsBoundsChangedNotifications = true
            NotificationCenter.default.addObserver(
                self, selector: #selector(handleChange(_:)),
                name: NSView.boundsDidChangeNotification, object: clipView
            )
        }
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleChange(_:)),
            name: NSView.frameDidChangeNotification, object: textView.enclosingScrollView
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleChange(_ notification: Notification) {
        updateFrame()
        needsDisplay = true
    }

    /// Recalculates gutter width based on line count and repositions the frame.
    func updateFrame() {
        guard let textView, let scrollView = textView.enclosingScrollView else { return }
        let lineCount = max(1, textView.string.components(separatedBy: "\n").count)
        let digitCount = String(lineCount).count
        let gutterWidth = CGFloat(max(30, digitCount * 8 + 16))

        // Fixed at the left edge of the scroll view, full visible height
        let visibleHeight = scrollView.contentView.bounds.height
        frame = NSRect(x: 0, y: 0, width: gutterWidth, height: visibleHeight)

        // Ensure text container inset leaves room for the gutter
        if textView.textContainerInset.width != gutterWidth {
            textView.textContainerInset = NSSize(width: gutterWidth, height: 16)
        }
    }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        guard let textView,
              let layoutManager = textView.layoutManager else { return }

        let scrollView = textView.enclosingScrollView
        let clipOrigin = scrollView?.contentView.bounds.origin ?? .zero
        let textInset = textView.textContainerInset

        // Draw background
        textView.backgroundColor.set()
        bounds.fill()

        // Draw separator line on the right edge
        NSColor.separatorColor.set()
        let separatorX = bounds.maxX - 0.5
        NSBezierPath.strokeLine(from: NSPoint(x: separatorX, y: 0),
                                to: NSPoint(x: separatorX, y: bounds.height))

        let attributes: [NSAttributedString.Key: Any] = [
            .font: lineNumberFont,
            .foregroundColor: textColor,
        ]

        let text = textView.string as NSString
        let totalLength = text.length

        var lineNumber = 1
        var glyphIndex = 0
        let numberOfGlyphs = layoutManager.numberOfGlyphs

        while glyphIndex < numberOfGlyphs {
            var lineRange = NSRange()
            let lineRect = layoutManager.lineFragmentRect(
                forGlyphAt: glyphIndex, effectiveRange: &lineRange
            )

            // Convert from text view coords to our local coords
            let y = lineRect.minY + textInset.height - clipOrigin.y
            let lineHeight = lineRect.height

            if y + lineHeight >= 0, y <= bounds.height {
                let label = "\(lineNumber)" as NSString
                let labelSize = label.size(withAttributes: attributes)
                let labelY = y + (lineHeight - labelSize.height) / 2.0
                let labelX = bounds.width - labelSize.width - 6

                label.draw(at: NSPoint(x: labelX, y: labelY), withAttributes: attributes)
            }

            glyphIndex = NSMaxRange(lineRange)
            lineNumber += 1
        }

        // If text ends with a newline, draw one more line number
        if totalLength > 0 && text.character(at: totalLength - 1) == UInt16(UnicodeScalar("\n").value) {
            let extraRect = layoutManager.extraLineFragmentRect
            if !extraRect.isEmpty {
                let y = extraRect.minY + textInset.height - clipOrigin.y
                let lineHeight = extraRect.height
                if y + lineHeight >= 0, y <= bounds.height {
                    let label = "\(lineNumber)" as NSString
                    let labelSize = label.size(withAttributes: attributes)
                    let labelY = y + (lineHeight - labelSize.height) / 2.0
                    let labelX = bounds.width - labelSize.width - 6
                    label.draw(at: NSPoint(x: labelX, y: labelY), withAttributes: attributes)
                }
            }
        }
    }
}
