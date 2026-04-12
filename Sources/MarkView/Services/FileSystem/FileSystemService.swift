import Foundation

enum FileSystemService {
    /// Recursively walks `root` and returns a `FileNode` tree.
    /// Directories come before files; within each group entries are sorted case-insensitively by name.
    /// Hidden files/directories (leading `.`) are skipped. Symbolic links are not followed.
    static func loadTree(at root: URL) async throws -> FileNode {
        try await Task.detached(priority: .userInitiated) {
            try buildNode(at: root, isRoot: true)
        }.value
    }

    /// Reads the file at `url` as UTF-8 text, off the main actor.
    static func read(_ url: URL) async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            do {
                return try String(contentsOf: url, encoding: .utf8)
            } catch {
                throw FileSystemError.unreadable(url, underlying: error)
            }
        }.value
    }

    /// Writes `contents` to `url` atomically as UTF-8 text, off the main actor.
    static func write(_ contents: String, to url: URL) async throws {
        try await Task.detached(priority: .userInitiated) {
            do {
                try contents.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                throw FileSystemError.unwritable(url, underlying: error)
            }
        }.value
    }

    private static func buildNode(at url: URL, isRoot: Bool) throws -> FileNode {
        let fm = FileManager.default
        let resourceKeys: Set<URLResourceKey> = [.isDirectoryKey, .isSymbolicLinkKey]

        let resourceValues: URLResourceValues
        do {
            resourceValues = try url.resourceValues(forKeys: resourceKeys)
        } catch {
            throw FileSystemError.unreadable(url, underlying: error)
        }

        let isDirectory = resourceValues.isDirectory ?? false

        if isRoot && !isDirectory {
            throw FileSystemError.notADirectory(url)
        }

        guard isDirectory else {
            return FileNode(
                url: url,
                name: url.lastPathComponent,
                isDirectory: false,
                children: nil
            )
        }

        let contents: [URL]
        do {
            contents = try fm.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: Array(resourceKeys),
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            )
        } catch {
            throw FileSystemError.unreadable(url, underlying: error)
        }

        var children: [FileNode] = []
        children.reserveCapacity(contents.count)

        for child in contents {
            let childValues = try? child.resourceValues(forKeys: resourceKeys)
            if childValues?.isSymbolicLink == true { continue }
            let childIsDir = childValues?.isDirectory ?? false

            if childIsDir {
                if let built = try? buildNode(at: child, isRoot: false) {
                    children.append(built)
                }
            } else {
                children.append(
                    FileNode(
                        url: child,
                        name: child.lastPathComponent,
                        isDirectory: false,
                        children: nil
                    )
                )
            }
        }

        children.sort { lhs, rhs in
            if lhs.isDirectory != rhs.isDirectory {
                return lhs.isDirectory && !rhs.isDirectory
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }

        return FileNode(
            url: url,
            name: url.lastPathComponent,
            isDirectory: true,
            children: children
        )
    }
}
