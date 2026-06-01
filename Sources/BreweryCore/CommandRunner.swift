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

            let stdout = Pipe()
            let stderr = Pipe()
            process.standardOutput = stdout
            process.standardError = stderr

            let lock = NSLock()
            var stdoutText = ""
            var stderrText = ""

            func append(_ data: Data, to stream: CommandLogEntry.Stream) {
                guard let text = String(data: data, encoding: .utf8), !text.isEmpty else { return }
                lock.lock()
                if stream == .stdout {
                    stdoutText += text
                } else {
                    stderrText += text
                }
                lock.unlock()
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
            append(stdout.fileHandleForReading.readDataToEndOfFile(), to: .stdout)
            append(stderr.fileHandleForReading.readDataToEndOfFile(), to: .stderr)

            return CommandResult(
                commandDisplay: display,
                stdout: stdoutText,
                stderr: stderrText,
                exitCode: process.terminationStatus,
                startedAt: startedAt,
                finishedAt: Date()
            )
        }.value
    }
}
