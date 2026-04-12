import SwiftUI
import AppKit

struct ContentView: View {
    @Bindable var workspace: WorkspaceState
    @Bindable var project: ProjectState

    var body: some View {
        NavigationSplitView(columnVisibility: $workspace.columnVisibility) {
            NavigatorView(project: project)
        } detail: {
            HSplitView {
                EditorPaneView(workspace: workspace)
                    .frame(minWidth: 320)
                    .layoutPriority(1)

                if workspace.isPreviewVisible {
                    PreviewPaneView(workspace: workspace)
                        .frame(minWidth: 240, idealWidth: 420)
                        .layoutPriority(1)
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 900, minHeight: 560)
        .task {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
        .onChange(of: project.selection) { _, newSelection in
            guard let url = newSelection else { return }
            Task { await workspace.openFile(url) }
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
            set: { newValue in
                if !newValue { workspace.closeConfirmation = nil }
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
