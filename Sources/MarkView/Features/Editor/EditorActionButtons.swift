import SwiftUI

struct EditorActionButtons: View {
    @Bindable var workspace: WorkspaceState

    private var hasActiveDocument: Bool {
        workspace.activeDocument != nil
    }

    var body: some View {
        HStack(spacing: 2) {
            Button {
                Task { await workspace.activeDocument?.save() }
            } label: {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(workspace.activeDocument?.isDirty == true ? .primary : .tertiary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Save")
            .disabled(workspace.activeDocument?.isDirty != true)

            toggleButton(
                icon: "textformat",
                tooltip: workspace.activeSession.isSyntaxHighlightingEnabled
                    ? "Disable syntax highlighting"
                    : "Enable syntax highlighting",
                isOn: workspace.activeSession.isSyntaxHighlightingEnabled
            ) {
                workspace.activeSession.isSyntaxHighlightingEnabled.toggle()
            }

            toggleButton(
                icon: workspace.activeSession.isEditorLightModeEnabled ? "sun.max.fill" : "moon.fill",
                tooltip: workspace.activeSession.isEditorLightModeEnabled
                    ? "Switch to dark mode"
                    : "Enable light mode",
                isOn: workspace.activeSession.isEditorLightModeEnabled
            ) {
                workspace.activeSession.isEditorLightModeEnabled.toggle()
            }

            toggleButton(
                icon: workspace.activeSession.isRendererCollapsed
                    ? "rectangle.righthalf.inset.filled.arrow.right"
                    : "rectangle.righthalf.inset.filled",
                tooltip: workspace.activeSession.isRendererCollapsed
                    ? "Show Preview Pane"
                    : "Hide Preview Pane",
                isOn: !workspace.activeSession.isRendererCollapsed
            ) {
                workspace.activeSession.isRendererCollapsed.toggle()
            }

            Divider()
                .frame(height: 14)
                .padding(.horizontal, 2)

            toggleButton(
                icon: "list.number",
                tooltip: workspace.activeSession.isLineNumbersEnabled
                    ? "Hide line numbers"
                    : "Show line numbers",
                isOn: workspace.activeSession.isLineNumbersEnabled
            ) {
                workspace.activeSession.isLineNumbersEnabled.toggle()
            }

            toggleButton(
                icon: "checklist",
                tooltip: workspace.activeSession.isLinterPaneVisible
                    ? "Hide Linter"
                    : "Show Linter",
                isOn: workspace.activeSession.isLinterPaneVisible
            ) {
                workspace.activeSession.isLinterPaneVisible.toggle()
            }
        }
        .disabled(!hasActiveDocument)
    }

    private func toggleButton(icon: String, tooltip: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isOn ? .primary : .tertiary)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isOn ? Color.accentColor.opacity(0.15) : .clear)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }
}
