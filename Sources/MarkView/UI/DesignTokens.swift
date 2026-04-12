import SwiftUI
import AppKit

enum DesignTokens {
    /// Sidebar, tab bar, preview header.
    static let sidebarBackground = Color.clear

    /// Primary editor/preview surface.
    static let paneBackground = Color.clear

    /// Navigator file tree background.
    static let navigatorBackground = Color.clear

    /// Editor text background.
    static let editorBackground = Color(nsColor: .textBackgroundColor)

    /// Status bar background.
    static let statusBarBackground = Color.clear

    // MARK: - Material styles for backgrounds

    /// Material for chrome surfaces (sidebar, tab bar, status bar, preview header).
    static let chromeMaterial: Material = .regularMaterial

    /// Material for content surfaces (navigator, preview pane).
    static let contentMaterial: Material = .thickMaterial

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
