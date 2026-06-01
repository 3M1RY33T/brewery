import XCTest
@testable import BreweryCore

final class BreweryCoreTests: XCTestCase {
    func testActionArgumentsDoNotShellInterpolatePackageNames() {
        let action = BrewAction.install(name: "bad; rm -rf /", kind: .cask)

        XCTAssertEqual(action.arguments, ["install", "--cask", "bad; rm -rf /"])
        XCTAssertEqual(action.commandDisplay, "brew install --cask bad; rm -rf /")
    }

    func testDecodesInstalledAndOutdatedPackages() throws {
        let decoder = JSONDecoder()
        let info = try decoder.decode(BrewInfoPayload.self, from: fixture("brew-info-v2-installed"))
        let outdated = try decoder.decode(OutdatedPayload.self, from: fixture("brew-outdated-v2"))

        let packages = BrewPackageMapper.packages(from: info, outdated: outdated)

        XCTAssertEqual(packages.count, 2)

        let wget = try XCTUnwrap(packages.first { $0.name == "wget" })
        XCTAssertEqual(wget.kind, .formula)
        XCTAssertEqual(wget.installedVersion, "1.24.5")
        XCTAssertEqual(wget.currentVersion, "1.25.0")
        XCTAssertTrue(wget.outdated)
        XCTAssertTrue(wget.pinned)
        XCTAssertEqual(wget.dependencies, ["openssl@3"])

        let code = try XCTUnwrap(packages.first { $0.name == "visual-studio-code" })
        XCTAssertEqual(code.kind, .cask)
        XCTAssertEqual(code.displayName, "Visual Studio Code")
        XCTAssertEqual(code.installedVersion, "1.100.0")
        XCTAssertFalse(code.outdated)
    }

    func testBuildsDependencyGraphFromRuntimeDependencies() throws {
        let decoder = JSONDecoder()
        let info = try decoder.decode(BrewInfoPayload.self, from: fixture("brew-info-v2-installed"))
        let inventory = BrewPackageMapper.inventory(from: info, outdated: nil)

        let wget = PackageNodeID(kind: .formula, name: "wget")
        let openssl = PackageNodeID(kind: .formula, name: "openssl@3")
        let caCertificates = PackageNodeID(kind: .formula, name: "ca-certificates")

        XCTAssertEqual(inventory.graph.directDependencies(of: wget), [openssl])
        XCTAssertEqual(inventory.graph.recursiveDependencies(of: wget), [caCertificates, openssl])
        XCTAssertEqual(inventory.graph.directDependents(of: openssl), [wget])
        XCTAssertTrue(inventory.graph.isRequiredByInstalledPackage(openssl))
        XCTAssertTrue(inventory.graph.isLeaf(wget))
    }

    func testDecodesCaskDependencyObjectsFromRealBrewOutput() throws {
        let decoder = JSONDecoder()
        let info = try decoder.decode(BrewInfoPayload.self, from: fixture("brew-info-v2-cask-depends-on"))

        let inventory = BrewPackageMapper.inventory(from: info, outdated: nil)
        let packages = inventory.packages

        let wine = try XCTUnwrap(packages.first { $0.name == "wine-stable" })
        XCTAssertEqual(wine.dependencies, ["gstreamer-runtime"])
        XCTAssertEqual(wine.installedVersion, "11.0_1")
        XCTAssertEqual(
            inventory.graph.directDependencies(of: PackageNodeID(kind: .cask, name: "wine-stable")),
            [PackageNodeID(kind: .cask, name: "gstreamer-runtime")]
        )
    }

    func testRecursiveDependencyTraversalHandlesCycles() {
        let a = PackageNodeID(kind: .formula, name: "a")
        let b = PackageNodeID(kind: .formula, name: "b")
        let c = PackageNodeID(kind: .formula, name: "c")
        let graph = BrewDependencyGraph(
            nodes: [a, b, c],
            edges: [
                DependencyEdge(from: a, to: b, relationship: .direct),
                DependencyEdge(from: b, to: c, relationship: .direct),
                DependencyEdge(from: c, to: a, relationship: .direct)
            ]
        )

        XCTAssertEqual(graph.recursiveDependencies(of: a), [b, c])
        XCTAssertEqual(graph.recursiveDependents(of: a), [b, c])
    }

    func testBrewDetectorFindsAppleSiliconPath() {
        let detector = BrewDetector(
            fileManager: StubFileManager(executablePaths: ["/opt/homebrew/bin/brew"]),
            shellLookup: { nil }
        )

        let report = detector.detect()

        XCTAssertEqual(report.foundPath, "/opt/homebrew/bin/brew")
        XCTAssertTrue(report.isAvailable)
    }

    func testBrewDetectorFallsBackToShellPath() {
        let detector = BrewDetector(
            fileManager: StubFileManager(executablePaths: ["/custom/bin/brew"]),
            shellLookup: { "/custom/bin/brew" }
        )

        let report = detector.detect()

        XCTAssertEqual(report.foundPath, "/custom/bin/brew")
        XCTAssertEqual(report.checkedPaths.last, "login shell PATH")
    }

    func testBrewDetectorReportsMissingBrew() {
        let detector = BrewDetector(
            fileManager: StubFileManager(executablePaths: []),
            shellLookup: { nil }
        )

        let report = detector.detect()

        XCTAssertNil(report.foundPath)
        XCTAssertFalse(report.isAvailable)
        XCTAssertNotNil(report.lookupError)
    }

    @MainActor
    func testPackageStoreFiltersOutdatedPackages() async {
        let store = PackageStore(service: MockBrewService())
        await store.refresh()

        store.filter = .outdated

        XCTAssertEqual(store.filteredPackages.map(\.name), ["wget"])
    }

    @MainActor
    func testPackageStoreExposesDependencyGraph() async {
        let store = PackageStore(service: MockBrewService())
        await store.refresh()

        let wget = try! XCTUnwrap(store.packages.first { $0.name == "wget" })

        XCTAssertEqual(store.directDependencies(for: wget), [PackageNodeID(kind: .formula, name: "openssl@3")])
        XCTAssertTrue(store.directDependents(for: wget).isEmpty)
    }

    private func fixture(_ name: String) throws -> Data {
        let url = try XCTUnwrap(Bundle.module.url(forResource: name, withExtension: "json"))
        return try Data(contentsOf: url)
    }
}

private final class StubFileManager: FileManager {
    private let executablePaths: Set<String>

    init(executablePaths: Set<String>) {
        self.executablePaths = executablePaths
        super.init()
    }

    override func isExecutableFile(atPath path: String) -> Bool {
        executablePaths.contains(path)
    }
}
