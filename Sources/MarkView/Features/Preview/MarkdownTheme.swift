import SwiftUI

private struct MarkdownThemeKey: EnvironmentKey {
    static let defaultValue: MarkdownTheme = .default
}

extension EnvironmentValues {
    var markdownTheme: MarkdownTheme {
        get { self[MarkdownThemeKey.self] }
        set { self[MarkdownThemeKey.self] = newValue }
    }
}

extension View {
    func markdownTheme(_ theme: MarkdownTheme) -> some View {
        environment(\.markdownTheme, theme)
    }
}

/// Visual theme for the markdown preview. Injected via the `markdownTheme(_:)`
/// view modifier; resolved by block views via the `\.markdownTheme` environment.
struct MarkdownTheme: Equatable, Sendable {
    var linkColor: Color
    var strikethroughColor: Color
    var codeBlockBackground: Color
    var blockQuoteRule: Color
    var blockQuoteText: Color
    var tableBackground: Color
    var tableBorder: Color
    var listMarkerColor: Color
    var checkboxCheckedColor: Color
    var checkboxUncheckedColor: Color

    /// Heading font sizes in points, h1..h6 (index 0 = h1).
    var headingSizes: [CGFloat]
    var bodyFontSize: CGFloat
    var codeFontSize: CGFloat

    /// Returns the heading font size for a 1-based level. Levels outside
    /// `1...headingSizes.count` are clamped to the nearest end of the table.
    func headingSize(level: Int) -> CGFloat {
        let i = max(1, min(level, headingSizes.count)) - 1
        return headingSizes[i]
    }

    static let `default` = MarkdownTheme(
        linkColor: Color(nsColor: .linkColor),
        strikethroughColor: .secondary,
        codeBlockBackground: Color.secondary.opacity(0.12),
        blockQuoteRule: Color.secondary.opacity(0.5),
        blockQuoteText: .secondary,
        tableBackground: Color.secondary.opacity(0.06),
        tableBorder: Color.secondary.opacity(0.2),
        listMarkerColor: .secondary,
        checkboxCheckedColor: .accentColor,
        checkboxUncheckedColor: .secondary,
        headingSizes: [28, 22, 18, 16, 14, 13],
        bodyFontSize: 14,
        codeFontSize: 13
    )
}
