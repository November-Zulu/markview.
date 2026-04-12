import SwiftUI

@main
struct MarkViewApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var workspace = WorkspaceState()
    @State private var project = ProjectState()
    private let closeInterceptor = WindowCloseInterceptor()

    var body: some Scene {
        WindowGroup("markview.") {
            ContentView(workspace: workspace, project: project)
                .onAppear {
                    AppDelegate.workspace = workspace
                    // Install close button interceptor on the window
                    DispatchQueue.main.async {
                        if let window = NSApp.windows.first {
                            closeInterceptor.install(on: window, workspace: workspace)
                        }
                    }
                }
                .task {
                    await project.restoreLastProject()
                    await workspace.restoreTabs()
                }
        }
        .defaultSize(width: 1200, height: 760)
        .windowToolbarStyle(.unified)
        .commands {
            AppCommands(workspace: workspace, project: project)
        }
    }
}
