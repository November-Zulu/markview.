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
}
