import SwiftUI

struct LinterPaneView: View {
    let violations: [LintViolation]
    let document: OpenDocument
    let lintSourceHash: Int?
    var onNavigate: (Int) -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack(spacing: 6) {
                Image(systemName: "checklist")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("Linter")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)

                if !violations.isEmpty {
                    Text("\(violations.count)")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.orange))
                }

                Spacer()

                // Autofix button (click action, not toggle)
                Button {
                    applyAutofix()
                } label: {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(hasFixableViolations ? .primary : .tertiary)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Autofix all fixable issues")
                .disabled(!hasFixableViolations)

                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Close Linter")
            }
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(DesignTokens.statusBarBackground)

            Divider()

            // Violations list
            if violations.isEmpty {
                VStack {
                    Spacer()
                    Text("No issues found")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(violations) { violation in
                            violationRow(violation)
                        }
                    }
                }
            }
        }
        .background(DesignTokens.editorBackground)
    }

    private var hasFixableViolations: Bool {
        violations.contains { $0.fix != nil }
    }

    private func violationRow(_ violation: LintViolation) -> some View {
        Button {
            onNavigate(violation.line)
        } label: {
            HStack(spacing: 8) {
                Text("L\(violation.line)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 40, alignment: .trailing)

                if violation.fix != nil {
                    Image(systemName: "wrench.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.orange)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.yellow)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(violation.message)
                        .font(.system(size: 11))
                        .foregroundStyle(.primary)
                    Text(violation.rule.displayName)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.clear)
    }

    private func applyAutofix() {
        guard let hash = lintSourceHash,
              document.content.hashValue == hash else { return }
        let fixed = MarkdownLinter.applyFixes(to: document.content, violations: violations)
        document.content = fixed
    }
}
