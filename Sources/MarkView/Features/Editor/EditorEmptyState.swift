import SwiftUI

struct EditorEmptyState: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.tertiary)
            Text("No File Open")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Select a Markdown file from the navigator to start editing.")
                .font(.callout)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.editorBackground)
    }
}

#Preview {
    EditorEmptyState()
        .frame(width: 500, height: 400)
}
