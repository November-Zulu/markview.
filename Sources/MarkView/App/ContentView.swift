import SwiftUI
import AppKit

struct ContentView: View {
    @Bindable var workspace: WorkspaceState
    @Bindable var project: ProjectState
    @State private var selection: SelectionCoordinator?

    var body: some View {
        VStack(spacing: 0) {
            NavigationSplitView(columnVisibility: $workspace.columnVisibility) {
                NavigatorView(project: project, workspace: workspace)
            } detail: {
                SplitEditorView(workspace: workspace)
            }
            .navigationSplitViewStyle(.balanced)
            .navigationTitle("markview.")

            Divider()
            StatusBarView(
                content: workspace.activeDocument?.content,
                lintViolationCount: workspace.activeDocument?.lintViolations.count ?? 0,
                onLintTap: {
                    workspace.activeSession.toggleLinterPane()
                }
            )
        }
        .frame(minWidth: 900, minHeight: 560)
        .task {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            if selection == nil {
                selection = SelectionCoordinator(project: project, workspace: workspace)
            }
        }
        .onChange(of: project.selection) { _, newSelection in
            Task { await selection?.navigatorDidSelect(newSelection) }
        }
        .onChange(of: workspace.activeDocumentID) { _, newID in
            selection?.tabDidActivate(newID)
        }
        .confirmationDialog(
            closeConfirmationTitle,
            isPresented: closeConfirmationBinding,
            titleVisibility: .visible,
            presenting: workspace.closeConfirmation
        ) { _ in
            Button("Save") {
                Task { await workspace.resolveCloseBySaving() }
            }
            Button("Don’t Save", role: .destructive) {
                workspace.resolveCloseByDiscarding()
            }
            Button("Cancel", role: .cancel) {
                workspace.cancelCloseRequest()
            }
        } message: { _ in
            Text("Your changes will be lost if you don’t save them.")
        }
        .alert(
            "Couldn’t save",
            isPresented: saveErrorBinding,
            presenting: workspace.activeDocument?.saveErrorMessage
        ) { _ in
            Button("OK", role: .cancel) {
                workspace.activeDocument?.saveErrorMessage = nil
            }
        } message: { message in
            Text(message)
        }
    }

    private var closeConfirmationTitle: String {
        guard let doc = workspace.closeConfirmation else { return "" }
        return "Do you want to save the changes you made to “\(doc.displayName)”?"
    }

    private var closeConfirmationBinding: Binding<Bool> {
        Binding(
            get: { workspace.closeConfirmation != nil },
            set: { _ in
                // No-op: button actions (save/discard/cancel) handle clearing closeConfirmation.
                // Setting nil here would race with the async save Task.
            }
        )
    }

    private var saveErrorBinding: Binding<Bool> {
        Binding(
            get: { workspace.activeDocument?.saveErrorMessage != nil },
            set: { newValue in
                if !newValue { workspace.activeDocument?.saveErrorMessage = nil }
            }
        )
    }
}

#Preview {
    ContentView(workspace: WorkspaceState(), project: ProjectState())
        .frame(width: 1200, height: 760)
}
