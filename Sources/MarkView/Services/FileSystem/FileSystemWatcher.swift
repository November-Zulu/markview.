import Foundation
import CoreServices

/// Watches a directory recursively for filesystem changes using macOS FSEvents.
/// Calls a debounced callback on the main actor when changes are detected.
@MainActor
final class FileSystemWatcher {
    private var stream: FSEventStreamRef?
    private var debounceTask: Task<Void, Never>?
    private let onChange: @MainActor () -> Void

    init(onChange: @escaping @MainActor () -> Void) {
        self.onChange = onChange
    }

    func watch(directory: URL) {
        stop()

        let path = directory.path as CFString
        let pathsToWatch = [path] as CFArray

        var context = FSEventStreamContext()
        context.info = Unmanaged.passUnretained(self).toOpaque()

        guard let stream = FSEventStreamCreate(
            nil,
            fsEventsCallback,
            &context,
            pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.3, // latency in seconds
            UInt32(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagNoDefer)
        ) else { return }

        self.stream = stream
        FSEventStreamScheduleWithRunLoop(
            stream,
            CFRunLoopGetMain(),
            CFRunLoopMode.defaultMode.rawValue
        )
        FSEventStreamStart(stream)
    }

    func stop() {
        debounceTask?.cancel()
        debounceTask = nil
        guard let stream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
    }

    /// Called from the C callback on the main thread.
    nonisolated func handleEvents() {
        Task { @MainActor [weak self] in
            self?.debounceTask?.cancel()
            self?.debounceTask = Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }
                self?.onChange()
            }
        }
    }
}

/// C function callback for FSEvents — bridges to the Swift class.
private func fsEventsCallback(
    _ streamRef: ConstFSEventStreamRef,
    _ clientCallBackInfo: UnsafeMutableRawPointer?,
    _ numEvents: Int,
    _ eventPaths: UnsafeMutableRawPointer,
    _ eventFlags: UnsafePointer<FSEventStreamEventFlags>,
    _ eventIds: UnsafePointer<FSEventStreamEventId>
) {
    guard let info = clientCallBackInfo else { return }
    let watcher = Unmanaged<FileSystemWatcher>.fromOpaque(info).takeUnretainedValue()
    watcher.handleEvents()
}
