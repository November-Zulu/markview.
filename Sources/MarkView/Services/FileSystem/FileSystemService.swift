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

    /// Creates an empty file with the given name inside `directory`, off the main actor.
    static func createFile(name: String, in directory: URL) async throws -> URL {
        try await Task.detached(priority: .userInitiated) {
            var fileName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !fileName.isEmpty else {
                throw FileSystemError.unwritable(directory, underlying: NSError(
                    domain: "MarkView", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "File name cannot be empty."]
                ))
            }
            // Append .md if no extension provided
            if !fileName.contains(".") {
                fileName += ".md"
            }
            let fileURL = directory.appending(path: fileName)
            let fm = FileManager.default
            if fm.fileExists(atPath: fileURL.path) {
                throw FileSystemError.unwritable(fileURL, underlying: NSError(
                    domain: "MarkView", code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "A file named \(fileName) already exists."]
                ))
            }
            do {
                try "".write(to: fileURL, atomically: true, encoding: .utf8)
            } catch {
                throw FileSystemError.unwritable(fileURL, underlying: error)
            }
            return fileURL
        }.value
    }

    /// Creates a directory with the given name inside `parent`, off the main actor.
    static func createDirectory(name: String, in parent: URL) async throws -> URL {
        try await Task.detached(priority: .userInitiated) {
            let dirName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !dirName.isEmpty else {
                throw FileSystemError.unwritable(parent, underlying: NSError(
                    domain: "MarkView", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Folder name cannot be empty."]
                ))
            }
            let dirURL = parent.appending(path: dirName)
            let fm = FileManager.default
            if fm.fileExists(atPath: dirURL.path) {
                throw FileSystemError.unwritable(dirURL, underlying: NSError(
                    domain: "MarkView", code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "A folder named \(dirName) already exists."]
                ))
            }
            do {
                try fm.createDirectory(at: dirURL, withIntermediateDirectories: false)
            } catch {
                throw FileSystemError.unwritable(dirURL, underlying: error)
            }
            return dirURL
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
