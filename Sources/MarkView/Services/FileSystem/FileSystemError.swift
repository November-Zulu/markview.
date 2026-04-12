import Foundation

enum FileSystemError: LocalizedError {
    case notADirectory(URL)
    case unreadable(URL, underlying: Error)
    case unwritable(URL, underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notADirectory(let url):
            return "“\(url.lastPathComponent)” is not a folder."
        case .unreadable(let url, _):
            return "Couldn’t read “\(url.lastPathComponent)”. Check the file exists and you have permission to open it."
        case .unwritable(let url, _):
            return "Couldn’t save “\(url.lastPathComponent)”. Check you have permission to write to it."
        }
    }
}
