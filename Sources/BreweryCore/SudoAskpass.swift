import Darwin
import Foundation

/// One password prompt from `sudo`, relayed while a Homebrew command runs.
public struct SudoPasswordPrompt: Equatable {
    /// sudo's own prompt text, usually "Password:".
    public let message: String
    /// The sudo process asking. After a wrong password sudo runs the helper
    /// again from the same process, so a repeated ID means "try again".
    public let sudoProcessID: Int32?

    public init(message: String, sudoProcessID: Int32?) {
        self.message = message
        self.sudoProcessID = sudoProcessID
    }

    /// Parses the helper's request: sudo's process ID, then its prompt,
    /// one per line.
    init?(request: String) {
        let lines = request.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
        guard lines.count == 2 else { return nil }
        sudoProcessID = Int32(lines[0])
        message = lines[1].trimmingCharacters(in: .newlines)
    }
}

/// Returns the password for a prompt, or nil to cancel it.
public typealias SudoPasswordHandler = @Sendable (SudoPasswordPrompt) async -> String?

/// Answers sudo's password prompts for Brewery, which has no terminal for
/// sudo to read one from.
///
/// Homebrew calls `sudo -A` whenever `SUDO_ASKPASS` is set, and sudo then
/// runs that program to get the password. The helper written here forwards
/// sudo's prompt over a Unix socket in a private directory and prints the
/// reply. A prompt nobody answers leaves the output empty, which sudo takes
/// as a cancelled prompt, so the command fails instead of hanging.
///
/// Only processes Brewery started, such as brew's sudo, are answered. Any
/// other program running as the user could otherwise connect while a
/// command runs and be handed the password.
public final class SudoAskpass {
    public let helperURL: URL
    let directoryURL: URL

    private let trustedAncestor: pid_t
    private let listener: Int32
    private let source: DispatchSourceRead
    private let lock = NSLock()
    private var handler: SudoPasswordHandler?

    static let directoryPrefix = "brewery-askpass."

    /// `trustedAncestor` is the process whose descendants may ask: Brewery.
    public init(
        parentDirectory: URL = FileManager.default.temporaryDirectory,
        trustedAncestor: pid_t = getpid()
    ) throws {
        self.trustedAncestor = trustedAncestor
        Self.removeAbandonedDirectories(in: parentDirectory)
        directoryURL = try Self.makePrivateDirectory(in: parentDirectory)
        helperURL = directoryURL.appendingPathComponent("askpass")

        let socketPath = directoryURL.appendingPathComponent("socket").path
        let descriptor: Int32
        do {
            try Self.writeHelper(to: helperURL, socketPath: socketPath)
            descriptor = try Self.openListener(at: socketPath)
        } catch {
            try? FileManager.default.removeItem(at: directoryURL)
            throw error
        }

        listener = descriptor
        source = DispatchSource.makeReadSource(
            fileDescriptor: descriptor,
            queue: DispatchQueue(label: "dev.brewery.sudo-askpass")
        )
        source.setEventHandler { [weak self] in
            self?.acceptConnections()
        }
        source.setCancelHandler {
            close(descriptor)
        }
        source.resume()
    }

    deinit {
        source.cancel()
        try? FileManager.default.removeItem(at: directoryURL)
    }

    /// The variables that point a brew command's sudo at this helper.
    public var environment: [String: String] {
        ["SUDO_ASKPASS": helperURL.path]
    }

    /// Answers prompts with `handler` only while `operation` runs; outside
    /// it, every prompt is refused.
    public func serving<T>(
        _ handler: @escaping SudoPasswordHandler,
        during operation: () async throws -> T
    ) async rethrows -> T {
        setHandler(handler)
        defer { setHandler(nil) }
        return try await operation()
    }

    private func setHandler(_ handler: SudoPasswordHandler?) {
        lock.lock()
        self.handler = handler
        lock.unlock()
    }

    private func currentHandler() -> SudoPasswordHandler? {
        lock.lock()
        defer { lock.unlock() }
        return handler
    }

    private func acceptConnections() {
        while true {
            let connection = accept(listener, nil, nil)
            guard connection >= 0 else { return }
            respond(on: connection)
        }
    }

    private func respond(on connection: Int32) {
        _ = fcntl(connection, F_SETFD, FD_CLOEXEC)
        // Darwin hands accepted sockets the listener's O_NONBLOCK.
        _ = fcntl(connection, F_SETFL, fcntl(connection, F_GETFL) & ~O_NONBLOCK)
        var on: Int32 = 1
        setsockopt(connection, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<Int32>.size))
        var timeout = timeval(tv_sec: 5, tv_usec: 0)
        setsockopt(connection, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))

        guard Self.peer(of: connection, descendsFrom: trustedAncestor),
              let prompt = Self.readPrompt(from: connection),
              let handler = currentHandler()
        else {
            close(connection)
            return
        }

        Task.detached {
            if let password = await handler(prompt) {
                Self.write(password + "\n", to: connection)
            }
            close(connection)
        }
    }

    /// The kernel records which process connected, and a process cannot
    /// choose its parent, so this holds for anything not started by
    /// `ancestor`: it never reaches it walking up its parents. A process
    /// orphaned on the way is refused too.
    static func peer(of connection: Int32, descendsFrom ancestor: pid_t) -> Bool {
        var current: pid_t = 0
        var length = socklen_t(MemoryLayout<pid_t>.size)
        guard getsockopt(connection, SOL_LOCAL, LOCAL_PEERPID, &current, &length) == 0 else { return false }

        // sudo's helper sits a handful of levels below brew; the cap only
        // guards against a loop.
        for _ in 0..<64 {
            if current == ancestor { return true }
            guard current > 1, let parent = parentProcessID(of: current) else { return false }
            current = parent
        }
        return false
    }

    private static func parentProcessID(of pid: pid_t) -> pid_t? {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        guard sysctl(&mib, u_int(mib.count), &info, &size, nil, 0) == 0, size > 0 else { return nil }
        return info.kp_eproc.e_ppid
    }

    private static func readPrompt(from connection: Int32) -> SudoPasswordPrompt? {
        var bytes: [UInt8] = []
        var buffer = [UInt8](repeating: 0, count: 512)
        while bytes.filter({ $0 == UInt8(ascii: "\n") }).count < 2, bytes.count < 4096 {
            let count = read(connection, &buffer, buffer.count)
            guard count > 0 else { break }
            bytes += buffer[0..<count]
        }
        return SudoPasswordPrompt(request: String(decoding: bytes, as: UTF8.self))
    }

    private static func write(_ text: String, to connection: Int32) {
        let bytes = Array(text.utf8)
        var offset = 0
        while offset < bytes.count {
            let written = bytes[offset...].withUnsafeBytes { Darwin.write(connection, $0.baseAddress, $0.count) }
            guard written > 0 else { return }
            offset += written
        }
    }

    /// mkdtemp makes the directory 0700, so only this user can reach the
    /// socket. The name carries the process ID for the cleanup below.
    private static func makePrivateDirectory(in parent: URL) throws -> URL {
        var template = Array(parent.appendingPathComponent("\(directoryPrefix)\(getpid()).XXXXXX").path.utf8CString)
        guard mkdtemp(&template) != nil else {
            throw SudoAskpassError.system("mkdtemp", errno)
        }
        return URL(fileURLWithPath: template.withUnsafeBufferPointer { String(cString: $0.baseAddress!) })
    }

    /// A Brewery that quits leaves its directory behind, since the service
    /// lives as long as the app; clear those whose process is gone.
    private static func removeAbandonedDirectories(in parent: URL) {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: parent.path)) ?? []
        for name in names where name.hasPrefix(directoryPrefix) {
            let parts = name.split(separator: ".")
            guard parts.count == 3, let pid = Int32(parts[1]), kill(pid, 0) == -1, errno == ESRCH else { continue }
            try? FileManager.default.removeItem(at: parent.appendingPathComponent(name))
        }
    }

    private static func openListener(at path: String) throws -> Int32 {
        var address = sockaddr_un()
        let bytes = Array(path.utf8)
        guard bytes.count < MemoryLayout.size(ofValue: address.sun_path) else {
            throw SudoAskpassError.socketPathTooLong(path)
        }
        address.sun_family = sa_family_t(AF_UNIX)
        address.sun_len = UInt8(MemoryLayout<sockaddr_un>.size)
        withUnsafeMutableBytes(of: &address.sun_path) { $0.copyBytes(from: bytes) }

        let descriptor = socket(AF_UNIX, SOCK_STREAM, 0)
        guard descriptor >= 0 else {
            throw SudoAskpassError.system("socket", errno)
        }
        // Process does not close inherited descriptors. A listener leaked
        // into brew's children would outlive Brewery and strand the helper.
        _ = fcntl(descriptor, F_SETFD, FD_CLOEXEC)

        let bound = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(descriptor, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        guard bound == 0,
              listen(descriptor, 8) == 0,
              fcntl(descriptor, F_SETFL, fcntl(descriptor, F_GETFL) | O_NONBLOCK) != -1
        else {
            let code = errno
            close(descriptor)
            throw SudoAskpassError.system("bind", code)
        }
        return descriptor
    }

    private static func writeHelper(to url: URL, socketPath: String) throws {
        let quotedSocket = "'" + socketPath.replacingOccurrences(of: "'", with: "'\\''") + "'"
        let script = """
        #!/bin/sh
        # Brewery's SUDO_ASKPASS helper: sends sudo's process ID and prompt to
        # the Brewery window and prints the password typed there. Printing
        # nothing tells sudo the prompt was cancelled.
        printf '%s\\n%s\\n' "$PPID" "$1" | /usr/bin/nc -U \(quotedSocket)

        """
        guard FileManager.default.createFile(
            atPath: url.path,
            contents: Data(script.utf8),
            attributes: [.posixPermissions: 0o700]
        ) else {
            throw SudoAskpassError.system("write \(url.lastPathComponent)", errno)
        }
    }
}

public enum SudoAskpassError: LocalizedError, Equatable {
    case socketPathTooLong(String)
    case system(String, Int32)

    public var errorDescription: String? {
        switch self {
        case .socketPathTooLong(let path):
            return "The password helper's socket path is too long: \(path)"
        case .system(let call, let code):
            return "\(call) failed: \(String(cString: strerror(code)))"
        }
    }
}
