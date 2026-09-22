import Combine
import Foundation

@MainActor
public final class PackageStore: ObservableObject {
    @Published public private(set) var packages: [BrewPackage] = []
    @Published public private(set) var dependencyGraph: BrewDependencyGraph = .empty
    @Published public var filter: PackageFilter = .browse
    @Published public var searchText: String = ""
    @Published public var selectedPackageID: BrewPackage.ID?
    @Published public private(set) var logEntries: [CommandLogEntry] = []
    @Published public private(set) var isRunningCommand = false
    @Published public private(set) var statusMessage = "Ready"
    @Published public private(set) var diagnostics: BrewDiagnostics?

    public let service: BrewServicing

    public init(service: BrewServicing = LiveBrewService()) {
        self.service = service
    }

    public var filteredPackages: [BrewPackage] {
        packages.filter { package in
            let matchesFilter: Bool
            switch filter {
            case .browse:
                matchesFilter = false
            case .library:
                matchesFilter = true
            case .diagnostics:
                matchesFilter = false
            }

            guard matchesFilter else { return false }
            guard !searchText.isEmpty else { return true }
            return package.name.localizedCaseInsensitiveContains(searchText)
                || package.displayName.localizedCaseInsensitiveContains(searchText)
                || (package.description?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    /// Nil until the user picks something. Nothing is selected on the
    /// user's behalf, because the info pane shows whenever this is set.
    public var selectedPackage: BrewPackage? {
        packages.first { $0.id == selectedPackageID }
    }

    public func refresh() async {
        guard service.brewPath != nil else {
            statusMessage = "Homebrew not found"
            return
        }

        await runTrackedCommand(status: "Refreshing packages") { [self] in
            let inventory = try await self.service.refreshInventory(onOutput: self.makeLogSink())
            self.packages = inventory.packages
            self.dependencyGraph = inventory.graph
            self.statusMessage = "Loaded \(inventory.packages.count) packages"
        }
    }

    public func perform(_ action: BrewAction) async {
        await runTrackedCommand(status: action.title) { [self] in
            let result = try await self.service.runAction(action, onOutput: self.makeLogSink())
            self.statusMessage = result.succeeded ? "Finished \(action.commandDisplay)" : "Failed \(action.commandDisplay)"
            if result.succeeded {
                try? await Task.sleep(nanoseconds: 250_000_000)
                let inventory = try await self.service.refreshInventory(onOutput: self.makeLogSink())
                self.packages = inventory.packages
                self.dependencyGraph = inventory.graph
            }
        }
    }

    public func loadDiagnostics() async {
        guard service.brewPath != nil else {
            statusMessage = "Homebrew not found"
            return
        }

        await runTrackedCommand(status: "Loading diagnostics") { [self] in
            self.diagnostics = try await self.service.diagnostics(onOutput: self.makeLogSink())
            self.statusMessage = "Diagnostics loaded"
        }
    }

    public func clearLog() {
        logEntries.removeAll()
    }

    public func directDependencies(for package: BrewPackage) -> [PackageNodeID] {
        dependencyGraph.directDependencies(of: package.nodeID)
    }

    public func recursiveDependencies(for package: BrewPackage) -> [PackageNodeID] {
        dependencyGraph.recursiveDependencies(of: package.nodeID)
    }

    public func directDependents(for package: BrewPackage) -> [PackageNodeID] {
        dependencyGraph.directDependents(of: package.nodeID)
    }

    public func recursiveDependents(for package: BrewPackage) -> [PackageNodeID] {
        dependencyGraph.recursiveDependents(of: package.nodeID)
    }

    public func package(for node: PackageNodeID) -> BrewPackage? {
        packages.first { $0.nodeID == node }
    }

    /// Selects an installed package and switches to the Library, the one
    /// view that lists every installed package, so following a dependency
    /// link always lands somewhere it is visible.
    public func selectPackage(_ node: PackageNodeID) {
        guard dependencyGraph.contains(node), package(for: node) != nil else { return }
        selectedPackageID = node.id
        filter = .library
    }

    private func runTrackedCommand(status: String, operation: @escaping () async throws -> Void) async {
        guard !isRunningCommand else {
            appendLog(.status, "Another command is already running.\n")
            return
        }

        isRunningCommand = true
        statusMessage = status
        do {
            try await operation()
        } catch {
            statusMessage = error.localizedDescription
            appendLog(.stderr, "\(error.localizedDescription)\n")
        }
        isRunningCommand = false
    }

    private func makeLogSink() -> @Sendable (CommandLogEntry.Stream, String) -> Void {
        { [weak self] stream, text in
            Task { @MainActor in
                self?.appendLog(stream, text)
            }
        }
    }

    private func appendLog(_ stream: CommandLogEntry.Stream, _ text: String) {
        logEntries.append(CommandLogEntry(date: Date(), stream: stream, text: text))
    }
}
