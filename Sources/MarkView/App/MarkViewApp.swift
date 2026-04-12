import SwiftUI

@main
struct MarkViewApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var workspace = WorkspaceState()
    @State private var project = ProjectState()

    var body: some Scene {
        WindowGroup("MarkView") {
            ContentView(workspace: workspace, project: project)
                .onAppear {
                    AppDelegate.workspace = workspace
                }
        }
        .defaultSize(width: 1200, height: 760)
        .commands {
            AppCommands(workspace: workspace, project: project)
        }
    }
}
