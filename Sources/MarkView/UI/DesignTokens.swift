import SwiftUI
import AppKit

enum DesignTokens {
    /// Slightly lighter than the window background in dark mode (like Finder's sidebar),
    /// and a hair darker than window background in light mode.
    static let sidebarBackground = Color(nsColor: NSColor(name: "MarkViewSidebarBackground") { appearance in
        let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        return isDark
            ? NSColor(calibratedWhite: 0.20, alpha: 1.0)
            : NSColor(calibratedWhite: 0.925, alpha: 1.0)
    })

    /// Primary editor/preview surface — matches the window background.
    static let paneBackground = Color(nsColor: .windowBackgroundColor)

    /// Editor text background — slightly different in some modes from the generic pane.
    static let editorBackground = Color(nsColor: .textBackgroundColor)

    /// Status bar background — matches the title bar / window chrome.
    static let statusBarBackground = Color(nsColor: .windowBackgroundColor)

    // MARK: - Syntax Highlighting Colors

    /// Syntax colors using standard AppKit system colors. These are dynamic (light/dark
    /// adaptive) and proven to work reliably with NSTextStorage attributes.
    enum SyntaxColors {
        static let heading1: NSColor = .systemBlue
        static let heading2: NSColor = .systemTeal
        static let heading3: NSColor = .systemPurple
        static let headingOther: NSColor = .systemGray
        static let strong: NSColor = .systemOrange
        static let emphasis: NSColor = .systemPink
        static let inlineCode: NSColor = .systemBrown
        static let codeBlock: NSColor = .secondaryLabelColor
        static let link: NSColor = .linkColor
        static let blockQuote: NSColor = .tertiaryLabelColor
        static let listMarker: NSColor = .systemTeal
        static let strikethrough: NSColor = .systemGray
        static let table: NSColor = .systemIndigo
    }

    // MARK: - Linter Colors

    enum LinterColors {
        static let warning: NSColor = .systemYellow
        static let error: NSColor = .systemRed
        static let fixable: NSColor = .systemOrange
    }
}
