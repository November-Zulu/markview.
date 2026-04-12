import SwiftUI

struct StatusBarView: View {
    let content: String?

    var body: some View {
        HStack {
            Spacer()
            Text("char \(characterCount) / words \(wordCount)")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundStyle(content != nil ? .secondary : .quaternary)
                .padding(.horizontal, 12)
        }
        .frame(height: 22)
        .background(DesignTokens.statusBarBackground)
    }

    private var characterCount: Int {
        content?.count ?? 0
    }

    private var wordCount: Int {
        guard let content, !content.isEmpty else { return 0 }
        return content.split { $0.isWhitespace || $0.isNewline }.count
    }
}
