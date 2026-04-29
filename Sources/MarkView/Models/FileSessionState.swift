import Foundation

struct FileSessionState {
    private(set) var splitRatio: CGFloat = 0.5
    private(set) var isRendererCollapsed: Bool = false
    private(set) var isSyntaxHighlightingEnabled: Bool = true
    private(set) var isEditorLightModeEnabled: Bool = false
    private(set) var isScrollLockEnabled: Bool = false
    private(set) var isPreviewLightModeEnabled: Bool = false
    private(set) var isLinterPaneVisible: Bool = false
    private(set) var isLineNumbersEnabled: Bool = false

    static let minSplitRatio: CGFloat = 0.25
    static let maxSplitRatio: CGFloat = 0.75

    mutating func setSplitRatio(_ ratio: CGFloat) {
        splitRatio = min(max(ratio, Self.minSplitRatio), Self.maxSplitRatio)
    }

    mutating func toggleSyntaxHighlighting() {
        isSyntaxHighlightingEnabled.toggle()
    }

    mutating func toggleEditorLightMode() {
        isEditorLightModeEnabled.toggle()
    }

    mutating func togglePreviewLightMode() {
        isPreviewLightModeEnabled.toggle()
    }

    mutating func toggleScrollLock() {
        isScrollLockEnabled.toggle()
    }

    mutating func toggleRendererCollapsed() {
        isRendererCollapsed.toggle()
    }

    mutating func toggleLinterPane() {
        isLinterPaneVisible.toggle()
    }

    mutating func setLinterPaneVisible(_ visible: Bool) {
        isLinterPaneVisible = visible
    }

    mutating func toggleLineNumbers() {
        isLineNumbersEnabled.toggle()
    }
}
