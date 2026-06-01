import Foundation

public final class MockBrewService: BrewServicing {
    public var detectionReport: BrewDetectionReport
    public var brewPath: URL?
    public var packages: [BrewPackage]
    public private(set) var actions: [BrewAction] = []

    public init(
        brewAvailable: Bool = true,
        packages: [BrewPackage] = MockBrewService.samplePackages
    ) {
        self.brewPath = brewAvailable ? URL(fileURLWithPath: "/opt/homebrew/bin/brew") : nil
        self.detectionReport = BrewDetectionReport(
            checkedPaths: ["/opt/homebrew/bin/brew", "/usr/local/bin/brew", "login shell PATH"],
            foundPath: brewAvailable ? "/opt/homebrew/bin/brew" : nil,
            lookupError: brewAvailable ? nil : "Homebrew was not found."
        )
        self.packages = packages
    }

    public func refreshPackages(onOutput: @escaping @Sendable (CommandLogEntry.Stream, String) -> Void) async throws -> [BrewPackage] {
        try await refreshInventory(onOutput: onOutput).packages
    }

    public func refreshInventory(onOutput: @escaping @Sendable (CommandLogEntry.Stream, String) -> Void) async throws -> BrewInventory {
        onOutput(.status, "Loaded mock packages\n")
        return BrewInventory(
            packages: packages,
            graph: BrewDependencyGraph(
                nodes: Set(packages.map(\.nodeID)),
                edges: [
                    DependencyEdge(
                        from: PackageNodeID(kind: .formula, name: "wget"),
                        to: PackageNodeID(kind: .formula, name: "openssl@3"),
                        relationship: .direct
                    )
                ]
            )
        )
    }

    public func runAction(_ action: BrewAction, onOutput: @escaping @Sendable (CommandLogEntry.Stream, String) -> Void) async throws -> CommandResult {
        actions.append(action)
        onOutput(.stdout, "Mock: \(action.commandDisplay)\n")
        return CommandResult(
            commandDisplay: action.commandDisplay,
            stdout: "ok",
            stderr: "",
            exitCode: 0,
            startedAt: Date(),
            finishedAt: Date()
        )
    }

    public func diagnostics(onOutput: @escaping @Sendable (CommandLogEntry.Stream, String) -> Void) async throws -> BrewDiagnostics {
        onOutput(.stdout, "Mock diagnostics\n")
        return BrewDiagnostics(version: "Homebrew 4.x", config: "mock config", doctor: "Your system is ready to brew.")
    }

    public static let samplePackages = [
        BrewPackage(
            name: "wget",
            kind: .formula,
            tap: "homebrew/core",
            description: "Internet file retriever",
            homepage: URL(string: "https://www.gnu.org/software/wget/"),
            installedVersion: "1.24.5",
            currentVersion: "1.25.0",
            dependencies: ["openssl@3"],
            pinned: false,
            outdated: true
        ),
        BrewPackage(
            name: "visual-studio-code",
            displayName: "Visual Studio Code",
            kind: .cask,
            tap: "homebrew/cask",
            description: "Open-source code editor",
            homepage: URL(string: "https://code.visualstudio.com/"),
            installedVersion: "1.100.0",
            currentVersion: "1.100.0"
        )
    ]
}
