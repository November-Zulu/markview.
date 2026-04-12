import AppKit

/// Handles unsaved-document prompts for both ⌘Q (applicationShouldTerminate)
/// and the window close button (intercepted via WindowCloseInterceptor).
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Weak reference so the delegate never prolongs the workspace's lifetime.
    weak static var workspace: WorkspaceState?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // In a .app bundle the icns lives in Contents/Resources/;
        // when running as a bare SPM executable it's inside the resource bundle.
        let iconURL = Bundle.main.url(forResource: "markview", withExtension: "icns")
            ?? Bundle.main.url(forResource: "MarkView", withExtension: "bundle")
                .flatMap { Bundle(url: $0) }?
                .url(forResource: "markview", withExtension: "icns")
        if let iconURL, let icon = NSImage(contentsOf: iconURL) {
            NSApp.applicationIconImage = icon
        }
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let workspace = Self.workspace else { return .terminateNow }
        return Self.promptToSaveDirtyDocuments(workspace: workspace)
    }

    /// Shows a save/discard/cancel alert if there are unsaved documents.
    /// Returns `.terminateNow` (proceed), `.terminateLater` (saving async),
    /// or `.terminateCancel` (user cancelled).
    @MainActor
    static func promptToSaveDirtyDocuments(workspace: WorkspaceState) -> NSApplication.TerminateReply {
        let dirty = workspace.openDocuments.filter(\.isDirty)
        guard !dirty.isEmpty else { return .terminateNow }

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "You have unsaved changes"
        if dirty.count == 1 {
            alert.informativeText = "Save changes to \"\(dirty[0].displayName)\" before closing?"
        } else {
            let names = dirty.map { "\"\($0.displayName)\"" }.joined(separator: ", ")
            alert.informativeText = "\(dirty.count) documents have unsaved changes (\(names)). Save them all before closing?"
        }
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Discard")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        switch response {
        case .alertFirstButtonReturn: // Save
            Task { @MainActor in
                var allOK = true
                for doc in dirty {
                    let ok = await doc.save()
                    if !ok { allOK = false }
                }
                NSApp.reply(toApplicationShouldTerminate: allOK)
            }
            return .terminateLater

        case .alertSecondButtonReturn: // Discard
            return .terminateNow

        default: // Cancel or dismissed
            return .terminateCancel
        }
    }
}

/// Intercepts the window close button (red X) to prompt for unsaved changes.
/// Installed as the target of the window's close button, avoiding replacement
/// of SwiftUI's NSWindowDelegate.
@MainActor
final class WindowCloseInterceptor: NSObject {
    weak var workspace: WorkspaceState?
    weak var window: NSWindow?

    func install(on window: NSWindow, workspace: WorkspaceState) {
        self.window = window
        self.workspace = workspace
        guard let closeButton = window.standardWindowButton(.closeButton) else { return }
        closeButton.target = self
        closeButton.action = #selector(handleClose(_:))
    }

    @objc private func handleClose(_ sender: Any?) {
        guard let workspace, let window else {
            window?.close()
            return
        }

        let dirty = workspace.openDocuments.filter(\.isDirty)
        guard !dirty.isEmpty else {
            window.close()
            return
        }

        let result = AppDelegate.promptToSaveDirtyDocuments(workspace: workspace)
        switch result {
        case .terminateNow:
            window.close()
        case .terminateLater:
            // Save is async; close after it completes
            Task { @MainActor in
                window.close()
            }
        case .terminateCancel:
            break // User cancelled, don't close
        @unknown default:
            break
        }
    }
}
