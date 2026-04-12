import AppKit

/// Handles `applicationShouldTerminate` to show an aggregate "save changes?" prompt
/// when the user quits with unsaved documents. The workspace reference is wired up
/// from `MarkViewApp` on scene appear.
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Weak reference so the delegate never prolongs the workspace's lifetime.
    weak static var workspace: WorkspaceState?

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let workspace = Self.workspace else { return .terminateNow }

        let dirty = workspace.openDocuments.filter(\.isDirty)
        guard !dirty.isEmpty else { return .terminateNow }

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "You have unsaved changes"
        if dirty.count == 1 {
            alert.informativeText = "Save changes to “\(dirty[0].displayName)” before quitting?"
        } else {
            let names = dirty.map { "“\($0.displayName)”" }.joined(separator: ", ")
            alert.informativeText = "\(dirty.count) documents have unsaved changes (\(names)). Save them all before quitting?"
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
