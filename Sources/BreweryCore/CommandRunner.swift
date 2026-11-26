import Foundation

public struct CommandResult: Equatable {
    public let commandDisplay: String
    public let stdout: String
    public let stderr: String
    public let exitCode: Int32
    public let startedAt: Date
    public let finishedAt: Date

    public var succeeded: Bool { exitCode == 0 }
}

public struct CommandLogEntry: Identifiable, Equatable {
    public enum Stream: String {
        case stdout
        case stderr
        case status
    }

    public let id = UUID()
    public let date: Date
    public let stream: Stream
    public let text: String
}

/// Decodes a byte stream as UTF-8 without losing a scalar split across
/// chunks: a multi-byte character cut in half would make the whole chunk
/// undecodable, and the old code silently dropped it. The incomplete tail
/// waits for the next chunk, and `flushing` delivers whatever is left when the
/// process ends.
struct UTF8StreamDecoder {
    private var carry = Data()

    mutating func decode(_ data: Data, flushing: Bool = false) -> String {
        carry.append(data)
        guard !carry.isEmpty else { return "" }

        var validCount = carry.count
        while validCount > 0, String(data: Data(carry.prefix(validCount)), encoding: .utf8) == nil {
            validCount -= 1
        }

        var text = String(decoding: carry.prefix(validCount), as: UTF8.self)
        carry = Data(carry.dropFirst(validCount))

        if flushing, !carry.isEmpty {
            text += String(decoding: carry, as: UTF8.self)
            carry = Data()
        }
        return text
    }
}

/// Collects a process's two output streams as text under one lock. A
/// reference type so the sendable readability handlers share it without
/// capturing mutable state.
private final class CommandOutputCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var stdoutDecoder = UTF8StreamDecoder()
    private var stderrDecoder = UTF8StreamDecoder()
    private var stdoutText = ""
    private var stderrText = ""

    var stdout: String { lock.lock(); defer { lock.unlock() }; return stdoutText }
    var stderr: String { lock.lock(); defer { lock.unlock() }; return stderrText }

    /// Returns the text this chunk completed, or nil when it produced none.
    func append(_ data: Data, to stream: CommandLogEntry.Stream, flushing: Bool = false) -> String? {
        guard !data.isEmpty || flushing else { return nil }
        lock.lock()
        defer { lock.unlock() }

        let text: String
        if stream == .stdout {
            text = stdoutDecoder.decode(data, flushing: flushing)
            stdoutText += text
        } else {
            text = stderrDecoder.decode(data, flushing: flushing)
            stderrText += text
        }
        return text.isEmpty ? nil : text
    }
}

public final class CommandRunner {
    public init() {}

    public func run(
        executableURL: URL,
        arguments: [String],
        environment: [String: String] = ProcessInfo.processInfo.environment,
        onOutput: @escaping @Sendable (CommandLogEntry.Stream, String) -> Void = { _, _ in }
    ) async throws -> CommandResult {
        let display = ([executableURL.path] + arguments).joined(separator: " ")
        return try await Task.detached(priority: .userInitiated) {
            let startedAt = Date()
            let process = Process()
            process.executableURL = executableURL
            process.arguments = arguments
            process.environment = environment
            // There is no terminal behind Brewery to answer a prompt, so any
            // prompt reads end-of-file and fails instead of waiting forever.
            // sudo's password prompts go through SUDO_ASKPASS instead.
            process.standardInput = FileHandle.nullDevice

            let stdout = Pipe()
            let stderr = Pipe()
            process.standardOutput = stdout
            process.standardError = stderr

            let collector = CommandOutputCollector()

            @Sendable func append(_ data: Data, to stream: CommandLogEntry.Stream, flushing: Bool = false) {
                guard let text = collector.append(data, to: stream, flushing: flushing) else { return }
                onOutput(stream, text)
            }

            stdout.fileHandleForReading.readabilityHandler = { handle in
                append(handle.availableData, to: .stdout)
            }
            stderr.fileHandleForReading.readabilityHandler = { handle in
                append(handle.availableData, to: .stderr)
            }

            try process.run()
            process.waitUntilExit()

            stdout.fileHandleForReading.readabilityHandler = nil
            stderr.fileHandleForReading.readabilityHandler = nil
            append(stdout.fileHandleForReading.readDataToEndOfFile(), to: .stdout, flushing: true)
            append(stderr.fileHandleForReading.readDataToEndOfFile(), to: .stderr, flushing: true)

            return CommandResult(
                commandDisplay: display,
                stdout: collector.stdout,
                stderr: collector.stderr,
                exitCode: process.terminationStatus,
                startedAt: startedAt,
                finishedAt: Date()
            )
        }.value
    }
}
