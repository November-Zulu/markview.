import AppKit

/// A vertical ruler view that draws line numbers alongside an NSTextView.
final class LineNumberRulerView: NSRulerView {

    private weak var textView: NSTextView?
    private let lineNumberFont = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
    private let textColor = NSColor.secondaryLabelColor

    init(textView: NSTextView) {
        self.textView = textView
        super.init(scrollView: textView.enclosingScrollView!, orientation: .verticalRuler)
        self.clientView = textView
        self.ruleThickness = 36

        NotificationCenter.default.addObserver(
            self, selector: #selector(textDidChange(_:)),
            name: NSText.didChangeNotification, object: textView
        )
        if let clipView = textView.enclosingScrollView?.contentView {
            clipView.postsBoundsChangedNotifications = true
            NotificationCenter.default.addObserver(
                self, selector: #selector(boundsDidChange(_:)),
                name: NSView.boundsDidChangeNotification, object: clipView
            )
        }
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func textDidChange(_ notification: Notification) {
        updateThickness()
        needsDisplay = true
    }

    @objc private func boundsDidChange(_ notification: Notification) {
        needsDisplay = true
    }

    private func updateThickness() {
        guard let textView else { return }
        let lineCount = max(1, textView.string.components(separatedBy: "\n").count)
        let digitCount = String(lineCount).count
        let newThickness = CGFloat(max(30, digitCount * 8 + 16))
        if ruleThickness != newThickness {
            ruleThickness = newThickness
        }
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }

        let visibleRect = scrollView?.contentView.bounds ?? rect
        let textInset = textView.textContainerInset

        // Draw background
        (textView.backgroundColor).set()
        rect.fill()

        // Draw separator line
        NSColor.separatorColor.set()
        let separatorX = bounds.maxX - 0.5
        NSBezierPath.strokeLine(from: NSPoint(x: separatorX, y: rect.minY),
                                to: NSPoint(x: separatorX, y: rect.maxY))

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
            let charIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
            var lineRange = NSRange()
            let lineRect = layoutManager.lineFragmentRect(
                forGlyphAt: glyphIndex, effectiveRange: &lineRange
            )

            let y = lineRect.minY + textInset.height - visibleRect.origin.y
            let lineHeight = lineRect.height

            // Only draw if visible
            if y + lineHeight >= rect.minY, y <= rect.maxY {
                let label = "\(lineNumber)" as NSString
                let labelSize = label.size(withAttributes: attributes)
                let labelY = y + (lineHeight - labelSize.height) / 2.0
                let labelX = bounds.width - labelSize.width - 6

                label.draw(at: NSPoint(x: labelX, y: labelY), withAttributes: attributes)
            }

            glyphIndex = NSMaxRange(lineRange)
            lineNumber += 1
        }

        // If the text ends with a newline, draw one more line number
        if totalLength > 0 && text.character(at: totalLength - 1) == UInt16(UnicodeScalar("\n").value) {
            let extraRect = layoutManager.extraLineFragmentRect
            if !extraRect.isEmpty {
                let y = extraRect.minY + textInset.height - visibleRect.origin.y
                let lineHeight = extraRect.height
                if y + lineHeight >= rect.minY, y <= rect.maxY {
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
