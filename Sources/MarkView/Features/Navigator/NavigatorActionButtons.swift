import SwiftUI

struct NavigatorActionButtons: View {
    @Bindable var project: ProjectState
    @Bindable var workspace: WorkspaceState

    @State private var isCreatingFile = false
    @State private var isCreatingFolder = false
    @State private var newItemName = ""
    @State private var createErrorMessage: String?

    var body: some View {
        HStack(spacing: 4) {
            iconButton("doc.badge.plus", tooltip: "Create a new markdown file") {
                newItemName = ""
                createErrorMessage = nil
                isCreatingFile = true
            }
            .popover(isPresented: $isCreatingFile) {
                createPopover(title: "New File", placeholder: "filename.md") {
                    await createFile()
                }
            }

            iconButton("folder.badge.plus", tooltip: "Create new folder") {
                newItemName = ""
                createErrorMessage = nil
                isCreatingFolder = true
            }
            .popover(isPresented: $isCreatingFolder) {
                createPopover(title: "New Folder", placeholder: "folder name") {
                    await createFolder()
                }
            }

            iconButton("arrow.clockwise", tooltip: "Refresh project folder") {
                Task { await project.refresh() }
            }

            iconButton("xmark", tooltip: "Close project") {
                closeProject()
            }
        }
    }

    private func iconButton(_ systemName: String, tooltip: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 20, height: 20)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }

    private func createPopover(title: String, placeholder: String, onSubmit: @escaping () async -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            TextField(placeholder, text: $newItemName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)
                .onSubmit {
                    Task { await onSubmit() }
                }
            if let error = createErrorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            HStack {
                Spacer()
                Button("Cancel") {
                    isCreatingFile = false
                    isCreatingFolder = false
                }
                Button("Create") {
                    Task { await onSubmit() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(12)
    }

    private func createFile() async {
        guard let directory = project.focusedDirectory() else { return }
        do {
            let fileURL = try await FileSystemService.createFile(name: newItemName, in: directory)
            isCreatingFile = false
            await project.refresh()
            // Open the newly created file
            await workspace.openFile(fileURL)
        } catch {
            createErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func createFolder() async {
        guard let directory = project.focusedDirectory() else { return }
        do {
            _ = try await FileSystemService.createDirectory(name: newItemName, in: directory)
            isCreatingFolder = false
            await project.refresh()
        } catch {
            createErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func closeProject() {
        // Close all open documents
        for doc in workspace.openDocuments {
            workspace.closeDocument(doc.id)
        }
        project.closeProject()
    }
}
