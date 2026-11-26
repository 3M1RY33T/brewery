import Foundation

public final class MockBrewService: BrewServicing {
    public var detectionReport: BrewDetectionReport
    public var brewPath: URL?
    public var packages: [BrewPackage]
    public private(set) var actions: [BrewAction] = []
    /// Prompts each action relays before finishing, standing in for sudo
    /// asking for a password. The answers land in `passwordAnswers`.
    public var passwordPrompts: [SudoPasswordPrompt] = []
    public private(set) var passwordAnswers: [String?] = []
    /// How each action exits once its prompts are answered.
    public var actionExitCode: Int32 = 0
    /// Emits a Homebrew-like script of phases and percentages instead of a
    /// single line, so a demo run exercises the download UI without installing
    /// anything. A debug-only launch argument turns it on.
    public var simulatesDownloads = false
    /// How long each simulated phase takes.
    public var simulatedPhaseDelay: TimeInterval = 0.9

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

    public func runAction(
        _ action: BrewAction,
        onOutput: @escaping @Sendable (CommandLogEntry.Stream, String) -> Void,
        onPasswordRequest: @escaping SudoPasswordHandler
    ) async throws -> CommandResult {
        actions.append(action)
        onOutput(.stdout, "Mock: \(action.commandDisplay)\n")

        if simulatesDownloads {
            await emitSimulatedDownload(for: action, onOutput: onOutput)
            if actionExitCode == 0 {
                registerOutcome(of: action)
            }
            return CommandResult(
                commandDisplay: action.commandDisplay,
                stdout: "ok",
                stderr: "",
                exitCode: actionExitCode,
                startedAt: Date(),
                finishedAt: Date()
            )
        }

        for prompt in passwordPrompts {
            let answer = await onPasswordRequest(prompt)
            passwordAnswers.append(answer)
            if answer == nil {
                return CommandResult(
                    commandDisplay: action.commandDisplay,
                    stdout: "",
                    stderr: "sudo: no password was provided\n",
                    exitCode: 1,
                    startedAt: Date(),
                    finishedAt: Date()
                )
            }
        }
        return CommandResult(
            commandDisplay: action.commandDisplay,
            stdout: "ok",
            stderr: "",
            exitCode: actionExitCode,
            startedAt: Date(),
            finishedAt: Date()
        )
    }

    public func diagnostics(onOutput: @escaping @Sendable (CommandLogEntry.Stream, String) -> Void) async throws -> BrewDiagnostics {
        onOutput(.stdout, "Mock diagnostics\n")
        return BrewDiagnostics(version: "Homebrew 4.x", config: "mock config", doctor: "Your system is ready to brew.")
    }

    /// The phases Homebrew prints for an install, slowed down enough to watch.
    private func emitSimulatedDownload(
        for action: BrewAction,
        onOutput: @escaping @Sendable (CommandLogEntry.Stream, String) -> Void
    ) async {
        guard !action.targets.isEmpty else {
            onOutput(.stdout, "==> Updating Homebrew...\n")
            await simulatedDelay()
            onOutput(.stdout, "==> Cleaning up...\n")
            await simulatedDelay()
            return
        }

        for target in action.targets {
            onOutput(.stdout, "==> Fetching \(target.name)\n")
            await simulatedDelay()
            onOutput(.stdout, "==> Downloading https://example.test/\(target.name)/download\n")

            for percent in stride(from: 10.0, through: 100.0, by: 15.0) {
                onOutput(.stdout, String(format: "  %5.1f%%\r", percent))
                await simulatedDelay(short: true)
            }
            onOutput(.stdout, "\n")
            await simulatedDelay()

            if target.kind == .cask {
                onOutput(.stdout, "==> Installing Cask \(target.name)\n")
            } else {
                onOutput(.stdout, "==> Pouring \(target.name)--1.0.bottle.tar.gz\n")
            }
            await simulatedDelay()
            onOutput(.stdout, "🍺  \(target.name) was successfully installed!\n")
            await simulatedDelay()
        }
    }

    private func simulatedDelay(short: Bool = false) async {
        let seconds = short ? simulatedPhaseDelay / 3 : simulatedPhaseDelay
        try? await Task.sleep(nanoseconds: UInt64(max(seconds, 0) * 1_000_000_000))
    }

    /// Records a "successful" simulated run in the inventory, so the refresh
    /// that follows an install shows the package exactly the way a real
    /// `brew install` would. Without this the entry vanishes at completion
    /// and never comes back, because the inventory never changed.
    private func registerOutcome(of action: BrewAction) {
        switch action {
        case .uninstall(let name, let kind):
            packages.removeAll { $0.name == name && $0.kind == kind }
        case .update, .cleanup:
            break
        case .install, .upgrade, .upgradeAll:
            for target in action.targets {
                upsert(BrewPackage(
                    name: target.name,
                    kind: target.kind,
                    installedVersion: "1.0.0",
                    currentVersion: "1.0.0"
                ))
            }
        }
    }

    private func upsert(_ package: BrewPackage) {
        if let index = packages.firstIndex(where: { $0.name == package.name && $0.kind == package.kind }) {
            packages[index] = package
        } else {
            packages.append(package)
        }
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
