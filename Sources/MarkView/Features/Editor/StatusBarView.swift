import SwiftUI

struct StatusBarView: View {
    let content: String?
    var lintViolationCount: Int = 0

    var body: some View {
        HStack {
            if lintViolationCount > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.orange)
                    Text("\(lintViolationCount) issue\(lintViolationCount == 1 ? "" : "s")")
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .padding(.leading, 12)
            }
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
