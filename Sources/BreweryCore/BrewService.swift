import Foundation

public struct BrewDiagnostics: Equatable {
    public let version: String
    public let config: String
    public let doctor: String
}

public protocol BrewServicing: AnyObject {
    var detectionReport: BrewDetectionReport { get }
    var brewPath: URL? { get }
    func refreshInventory(onOutput: @escaping @Sendable (CommandLogEntry.Stream, String) -> Void) async throws -> BrewInventory
    func refreshPackages(onOutput: @escaping @Sendable (CommandLogEntry.Stream, String) -> Void) async throws -> [BrewPackage]
    /// `onPasswordRequest` answers sudo when the action needs administrator
    /// rights, as cask installers and uninstallers often do.
    func runAction(
        _ action: BrewAction,
        onOutput: @escaping @Sendable (CommandLogEntry.Stream, String) -> Void,
        onPasswordRequest: @escaping SudoPasswordHandler
    ) async throws -> CommandResult
    func diagnostics(onOutput: @escaping @Sendable (CommandLogEntry.Stream, String) -> Void) async throws -> BrewDiagnostics
}

public final class LiveBrewService: BrewServicing {
    public let detectionReport: BrewDetectionReport
    public let brewPath: URL?

    private let runner: CommandRunner
    private let decoder: JSONDecoder
    private var askpass: SudoAskpass?

    public init(detector: BrewDetector = BrewDetector(), runner: CommandRunner = CommandRunner()) {
        let report = detector.detect()
        detectionReport = report
        brewPath = report.foundPath.map(URL.init(fileURLWithPath:))
        self.runner = runner
        decoder = JSONDecoder()
    }

    public func refreshInventory(onOutput: @escaping @Sendable (CommandLogEntry.Stream, String) -> Void) async throws -> BrewInventory {
        let info = try await runBrewJSON([ "info", "--json=v2", "--installed" ], as: BrewInfoPayload.self, onOutput: onOutput)
        let outdated = try? await runBrewJSON([ "outdated", "--json=v2" ], as: OutdatedPayload.self, onOutput: onOutput)
        return BrewPackageMapper.inventory(from: info, outdated: outdated)
    }

    public func refreshPackages(onOutput: @escaping @Sendable (CommandLogEntry.Stream, String) -> Void) async throws -> [BrewPackage] {
        try await refreshInventory(onOutput: onOutput).packages
    }

    public func runAction(
        _ action: BrewAction,
        onOutput: @escaping @Sendable (CommandLogEntry.Stream, String) -> Void,
        onPasswordRequest: @escaping SudoPasswordHandler
    ) async throws -> CommandResult {
        guard let askpass = askpassHelper(onOutput: onOutput) else {
            return try await runBrew(action.arguments, onOutput: onOutput)
        }
        return try await askpass.serving(onPasswordRequest) {
            try await runBrew(action.arguments, environment: askpass.environment, onOutput: onOutput)
        }
    }

    /// Made on the first action rather than at launch, so browsing alone
    /// never leaves a helper in the temporary directory.
    private func askpassHelper(onOutput: @Sendable (CommandLogEntry.Stream, String) -> Void) -> SudoAskpass? {
        if let askpass { return askpass }
        do {
            askpass = try SudoAskpass()
        } catch {
            onOutput(.stderr, "Brewery cannot ask for your password, so steps that need sudo will fail. \(error.localizedDescription)\n")
        }
        return askpass
    }

    public func diagnostics(onOutput: @escaping @Sendable (CommandLogEntry.Stream, String) -> Void) async throws -> BrewDiagnostics {
        async let version = runBrew(["--version"], onOutput: onOutput).stdout
        async let config = runBrew(["config"], onOutput: onOutput).stdout
        async let doctor = runBrew(["doctor"], onOutput: onOutput).stdout
        return try await BrewDiagnostics(version: version, config: config, doctor: doctor)
    }

    private func runBrewJSON<T: Decodable>(
        _ arguments: [String],
        as type: T.Type,
        onOutput: @escaping @Sendable (CommandLogEntry.Stream, String) -> Void
    ) async throws -> T {
        let result = try await runBrew(arguments) { stream, text in
            if stream != .stdout {
                onOutput(stream, text)
            }
        }
        guard result.succeeded else {
            throw BrewServiceError.commandFailed(result.commandDisplay, result.stderr)
        }
        do {
            return try decoder.decode(T.self, from: Data(result.stdout.utf8))
        } catch {
            throw BrewServiceError.decodingFailed(BrewActionDisplay.display(arguments: arguments), error.localizedDescription)
        }
    }

    private func runBrew(
        _ arguments: [String],
        environment overrides: [String: String] = [:],
        onOutput: @escaping @Sendable (CommandLogEntry.Stream, String) -> Void
    ) async throws -> CommandResult {
        guard let brewPath else { throw BrewServiceError.brewNotFound(detectionReport) }
        onOutput(.status, "Running \(BrewActionDisplay.display(arguments: arguments))\n")
        let environment = ProcessInfo.processInfo.environment.merging(overrides) { _, override in override }
        return try await runner.run(executableURL: brewPath, arguments: arguments, environment: environment, onOutput: onOutput)
    }
}

public enum BrewServiceError: LocalizedError, Equatable {
    case brewNotFound(BrewDetectionReport)
    case commandFailed(String, String)
    case decodingFailed(String, String)

    public var errorDescription: String? {
        switch self {
        case .brewNotFound:
            return "Homebrew is not available."
        case .commandFailed(let command, let stderr):
            return "\(command) failed. \(stderr)"
        case .decodingFailed(let command, let details):
            return "Could not read Homebrew JSON from \(command). \(details)"
        }
    }
}

enum BrewActionDisplay {
    static func display(arguments: [String]) -> String {
        (["brew"] + arguments).joined(separator: " ")
    }
}
