import SwiftUI

@main
struct MarkViewApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var workspace = WorkspaceState()
    @State private var project = ProjectState()

    var body: some Scene {
        WindowGroup("markview.") {
            ContentView(workspace: workspace, project: project)
                .onAppear {
                    AppDelegate.workspace = workspace
                }
                .task {
                    await project.restoreLastProject()
                }
        }
        .defaultSize(width: 1200, height: 760)
        .windowToolbarStyle(.unified)
        .commands {
            AppCommands(workspace: workspace, project: project)
        }
    }
}
