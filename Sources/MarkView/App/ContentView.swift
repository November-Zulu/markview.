import SwiftUI
import AppKit

struct ContentView: View {
    @Bindable var workspace: WorkspaceState
    @Bindable var project: ProjectState

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
                lintViolationCount: workspace.activeDocument?.lintViolations.count ?? 0
            )
        }
        .frame(minWidth: 900, minHeight: 560)
        .task {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
        .onChange(of: project.selection) { _, newSelection in
            guard let url = newSelection,
                  !url.hasDirectoryPath else { return }
            Task { await workspace.openFile(url) }
        }
        .onChange(of: workspace.activeDocumentID) { _, newID in
            if project.selection != newID {
                project.selection = newID
            }
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
