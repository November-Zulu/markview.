import SwiftUI

struct AppCommands: Commands {
    @Bindable var workspace: WorkspaceState
    @Bindable var project: ProjectState

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Open File…") {
                Task { await OpenPrompts.presentOpenFile(into: workspace) }
            }
            .keyboardShortcut("o", modifiers: [.command])

            Button("Open Folder…") {
                Task { await OpenPrompts.presentOpenFolder(into: project) }
            }
            .keyboardShortcut("o", modifiers: [.command, .shift])

            Divider()

            Button("Save") {
                Task { _ = await workspace.activeDocument?.save() }
            }
            .keyboardShortcut("s", modifiers: [.command])
            .disabled(workspace.activeDocument?.isDirty != true)

            Button("Close Tab") {
                if let id = workspace.activeDocumentID {
                    workspace.requestClose(id)
                }
            }
            .keyboardShortcut("w", modifiers: [.command])
            .disabled(workspace.activeDocumentID == nil)
        }

        CommandGroup(replacing: .sidebar) {
            Button(workspace.columnVisibility == .all ? "Hide Navigator" : "Show Navigator") {
                workspace.toggleNavigator()
            }
            .keyboardShortcut("s", modifiers: [.command, .option])

            Button(workspace.isPreviewVisible ? "Hide Preview" : "Show Preview") {
                workspace.togglePreview()
            }
            .keyboardShortcut("p", modifiers: [.command, .option])

            Divider()
        }
    }
}
