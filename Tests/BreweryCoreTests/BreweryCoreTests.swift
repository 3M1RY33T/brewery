import CoreGraphics
import ImageIO
import XCTest
@testable import BreweryCore

final class BreweryCoreTests: XCTestCase {
    func testActionArgumentsDoNotShellInterpolatePackageNames() {
        let action = BrewAction.install(name: "bad; rm -rf /", kind: .cask)

        XCTAssertEqual(action.arguments, ["install", "--cask", "bad; rm -rf /"])
        XCTAssertEqual(action.commandDisplay, "brew install --cask bad; rm -rf /")
    }

    func testUpgradeAllNamesEveryPackageAsItsOwnArgument() {
        let casks = BrewAction.upgradeAll(names: ["firefox", "vlc", "bad; rm -rf /"], kind: .cask)
        XCTAssertEqual(casks.arguments, ["upgrade", "--cask", "firefox", "vlc", "bad; rm -rf /"])
        XCTAssertEqual(casks.title, "Upgrade 3 Casks")

        let formulae = BrewAction.upgradeAll(names: ["wget"], kind: .formula)
        XCTAssertEqual(formulae.arguments, ["upgrade", "wget"])
        XCTAssertEqual(formulae.title, "Upgrade 1 Formula")
        XCTAssertEqual(formulae.commandDisplay, "brew upgrade wget")
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
        XCTAssertEqual(code.appBundleName, "Visual Studio Code.app")
        XCTAssertNil(wget.appBundleName)
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

    func testDecodesCatalogFixtures() throws {
        let formulae = try CatalogPackageMapper.formulaPackages(from: fixture("catalog-formula"))
        let casks = try CatalogPackageMapper.caskPackages(from: fixture("catalog-cask"))

        let wget = try XCTUnwrap(formulae.first { $0.name == "wget" })
        XCTAssertEqual(wget.kind, .formula)
        XCTAssertEqual(wget.version, "1.25.0")
        XCTAssertEqual(wget.dependencies, ["openssl@3"])

        let code = try XCTUnwrap(casks.first { $0.name == "visual-studio-code" })
        XCTAssertEqual(code.kind, .cask)
        XCTAssertEqual(code.displayName, "Visual Studio Code")
        XCTAssertEqual(code.dependencies, ["mono-mdk"])
        XCTAssertEqual(code.appBundleName, "Visual Studio Code.app")

        let vlc = try XCTUnwrap(casks.first { $0.name == "vlc" })
        XCTAssertEqual(vlc.appBundleName, "VLC.app")

        let font = try XCTUnwrap(casks.first { $0.name == "font-hack-nerd-font" })
        XCTAssertNil(font.appBundleName)

        XCTAssertTrue(formulae.allSatisfy { $0.appBundleName == nil })
    }

    func testCatalogSearchSplitsResultsByKind() throws {
        let packages = try CatalogPackageMapper.formulaPackages(from: fixture("catalog-formula"))
            + CatalogPackageMapper.caskPackages(from: fixture("catalog-cask"))

        let results = CatalogSearch.searchResults(packages, searchText: "wget")
        XCTAssertEqual(results.formulae.first?.name, "wget")
        XCTAssertTrue(results.casks.allSatisfy { $0.kind == .cask })

        let code = CatalogSearch.searchResults(packages, searchText: "visual studio")
        XCTAssertEqual(code.casks.first?.name, "visual-studio-code")
        XCTAssertTrue(code.formulae.allSatisfy { $0.kind == .formula })

        XCTAssertTrue(CatalogSearch.searchResults(packages, searchText: "   ").isEmpty)
    }

    func testShelvesRankByInstallCountAndSplitByKind() throws {
        let packages = [
            CatalogPackage(name: "rare-app", kind: .cask, description: "Video player", popularity: 10),
            CatalogPackage(name: "popular-app", kind: .cask, description: "Video player", popularity: 9_000),
            CatalogPackage(name: "ffmpeg", kind: .formula, description: "Play, record and convert audio", popularity: 500)
        ]

        let sections = CatalogSearch.sections(packages)
        let featured = try XCTUnwrap(sections.first { $0.category == .featured })

        // Featured is a ranking across everything, most installed first.
        XCTAssertEqual(featured.casks.map(\.name), ["popular-app", "rare-app"])
        XCTAssertEqual(featured.formulae.map(\.name), ["ffmpeg"])

        let media = sections.first { $0.category == .media }
        XCTAssertEqual(media?.casks.map(\.name), ["popular-app", "rare-app"])
        XCTAssertEqual(media?.formulae.map(\.name), ["ffmpeg"])

        // Empty shelves are not rendered at all.
        XCTAssertFalse(sections.contains { $0.isEmpty })
    }

    func testShelvesCapEachKindButReportTheTrueTotal() {
        let packages = (0..<40).map {
            CatalogPackage(name: "cask-\($0)", kind: .cask, description: "Video player", popularity: 40 - $0)
        }

        let media = CatalogSearch.sections(packages, caskLimit: 5, formulaLimit: 5)
            .first { $0.category == .media }

        XCTAssertEqual(media?.casks.count, 5)
        XCTAssertEqual(media?.caskTotal, 40)
        XCTAssertEqual(media?.casks.first?.name, "cask-0")
    }

    func testFeaturedCarriesEnoughForTheChartsWhileSubjectShelvesStayCapped() {
        let packages = (0..<150).map {
            CatalogPackage(name: "app-\($0)", kind: .cask, description: "Video player", popularity: 150 - $0)
        }

        let sections = CatalogSearch.sections(packages, caskLimit: 16, featuredLimit: 100)

        XCTAssertEqual(sections.first { $0.category == .featured }?.casks.count, 100)
        XCTAssertEqual(sections.first { $0.category == .media }?.casks.count, 16)
        XCTAssertEqual(sections.first { $0.category == .media }?.caskTotal, 150)
    }

    func testEveryPackageLandsOnExactlyOneSubjectShelf() throws {
        let packages = try CatalogPackageMapper.formulaPackages(from: fixture("catalog-formula"))
            + CatalogPackageMapper.caskPackages(from: fixture("catalog-cask"))

        for package in packages {
            let category = CatalogSearch.category(for: package)
            XCTAssertNotEqual(category, .featured, "\(package.name) was assigned to a ranking, not a subject")
        }

        // Subject shelves never repeat a package; featured deliberately does.
        let sections = CatalogSearch.sections(packages).filter { $0.category != .featured }
        let placed = sections.flatMap { $0.casks + $0.formulae }.map(\.id)
        XCTAssertEqual(placed.count, Set(placed).count)
    }

    func testCategoryKeywordsMatchWholeWordsNotSubstrings() {
        // "ai" must not claim "email", "maintain" or "chain".
        let mail = CatalogPackage(name: "mailcheck", kind: .formula, description: "Check email from the terminal")
        XCTAssertNotEqual(CatalogSearch.category(for: mail), .ai)

        let llm = CatalogPackage(name: "ollama", kind: .formula, description: "Run an LLM locally")
        XCTAssertEqual(CatalogSearch.category(for: llm), .ai)

        let phrase = CatalogPackage(name: "torch", kind: .formula, description: "Machine learning framework")
        XCTAssertEqual(CatalogSearch.category(for: phrase), .ai)
    }

    func testPackagesNothingClaimsFallBackToUtilities() {
        let obscure = CatalogPackage(name: "zzz", kind: .formula, description: "Qwerty widget doohickey")
        XCTAssertEqual(CatalogSearch.category(for: obscure), .utilities)
    }

    func testCatalogMergeMarksInstalledAndOutdatedPackages() throws {
        let packages = try CatalogPackageMapper.formulaPackages(from: fixture("catalog-formula"))
            + CatalogPackageMapper.caskPackages(from: fixture("catalog-cask"))
        let installed = [
            BrewPackage(name: "wget", kind: .formula, outdated: true),
            BrewPackage(name: "visual-studio-code", kind: .cask)
        ]

        let merged = CatalogSearch.merge(packages, installedPackages: installed)

        XCTAssertEqual(merged.first { $0.name == "wget" }?.installStatus, .installed(outdated: true))
        XCTAssertEqual(merged.first { $0.name == "visual-studio-code" }?.installStatus, .installed(outdated: false))
        XCTAssertEqual(merged.first { $0.name == "ripgrep" }?.installStatus, .notInstalled)
    }

    @MainActor
    func testCatalogStoreFallsBackToCachedCatalogWhenRefreshFails() async throws {
        let cacheURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("brewery-catalog-test-\(UUID().uuidString).json")
        let formulaURL = URL(string: "https://example.test/formula.json")!
        let caskURL = URL(string: "https://example.test/cask.json")!
        let successStore = CatalogStore(
            fetcher: MockCatalogFetcher(payloads: [
                formulaURL: try fixture("catalog-formula"),
                caskURL: try fixture("catalog-cask")
            ]),
            cacheURL: cacheURL,
            formulaURL: formulaURL,
            caskURL: caskURL
        )

        await successStore.load(installedPackages: [], forceRefresh: true)
        XCTAssertFalse(successStore.packages.isEmpty)
        // Analytics were not stubbed, so the catalog must still build shelves.
        XCTAssertFalse(successStore.sections.isEmpty)

        let failingStore = CatalogStore(
            fetcher: MockCatalogFetcher(error: CatalogError.httpStatus(500)),
            cacheURL: cacheURL,
            formulaURL: formulaURL,
            caskURL: caskURL
        )

        await failingStore.load(installedPackages: [], forceRefresh: true)

        XCTAssertEqual(failingStore.statusMessage, "Using cached catalog")
        XCTAssertEqual(failingStore.packages.count, successStore.packages.count)
        XCTAssertEqual(failingStore.sections.count, successStore.sections.count)
    }

    @MainActor
    func testAnalyticsOrderTheShelvesWhenAvailable() async throws {
        let formulaURL = URL(string: "https://example.test/formula.json")!
        let caskURL = URL(string: "https://example.test/cask.json")!
        let formulaAnalyticsURL = URL(string: "https://example.test/analytics-formula.json")!
        let caskAnalyticsURL = URL(string: "https://example.test/analytics-cask.json")!

        let store = CatalogStore(
            fetcher: MockCatalogFetcher(payloads: [
                formulaURL: try fixture("catalog-formula"),
                caskURL: try fixture("catalog-cask"),
                formulaAnalyticsURL: try fixture("analytics-formula"),
                caskAnalyticsURL: try fixture("analytics-cask")
            ]),
            cacheURL: URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("brewery-analytics-test-\(UUID().uuidString).json"),
            formulaURL: formulaURL,
            caskURL: caskURL,
            formulaAnalyticsURL: formulaAnalyticsURL,
            caskAnalyticsURL: caskAnalyticsURL
        )

        await store.load(installedPackages: [], forceRefresh: true)

        let featured = try XCTUnwrap(store.sections.first { $0.category == .featured })
        // ripgrep has 900,000 installs against wget's 1,200; vlc beats VS Code.
        XCTAssertEqual(featured.formulae.first?.name, "ripgrep")
        XCTAssertEqual(featured.casks.first?.name, "vlc")

        let ripgrep = try XCTUnwrap(store.packages.first { $0.name == "ripgrep" })
        XCTAssertEqual(ripgrep.popularity, 900_000)
    }

    func testInstallCountsParseCommaFormattedNumbers() throws {
        let counts = try CatalogPackageMapper.installCounts(from: fixture("analytics-cask"), kind: .cask)
        XCTAssertEqual(counts["vlc"], 400_000)
        XCTAssertEqual(counts["visual-studio-code"], 50)
        XCTAssertNil(counts["not-a-cask"])
    }

    @MainActor
    func testCacheWrittenByAnOlderBuildIsRefetchedNotTrusted() async throws {
        let cacheURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("brewery-stale-cache-\(UUID().uuidString).json")
        addTeardownBlock { try? FileManager.default.removeItem(at: cacheURL) }

        // A v1 cache: no popularity, so its shelves would be alphabetical.
        let legacy: [String: Any] = [
            "fetchedAt": Date().timeIntervalSinceReferenceDate,
            "packages": [["name": "wget", "displayName": "wget", "kind": "formula", "dependencies": []]]
        ]
        try JSONSerialization.data(withJSONObject: legacy).write(to: cacheURL)

        let formulaURL = URL(string: "https://example.test/formula.json")!
        let caskURL = URL(string: "https://example.test/cask.json")!
        let store = CatalogStore(
            fetcher: MockCatalogFetcher(payloads: [
                formulaURL: try fixture("catalog-formula"),
                caskURL: try fixture("catalog-cask")
            ]),
            cacheURL: cacheURL,
            formulaURL: formulaURL,
            caskURL: caskURL
        )

        // Not a forced refresh: the stale cache must still be rejected.
        await store.load(installedPackages: [])

        XCTAssertTrue(store.packages.contains { $0.name == "visual-studio-code" })
        XCTAssertEqual(
            try JSONDecoder().decode(CatalogSnapshot.self, from: Data(contentsOf: cacheURL)).version,
            CatalogSnapshot.currentVersion
        )
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
    func testLibraryLeadsWithOutdatedPackages() async {
        let store = PackageStore(service: MockBrewService())
        await store.refresh()

        store.filter = .library
        let ordered = store.filteredPackages.outdatedFirst()

        XCTAssertEqual(ordered.first?.name, "wget", "the one outdated mock package leads")
        XCTAssertTrue(ordered.dropFirst().allSatisfy { !$0.outdated })
    }

    @MainActor
    func testPinnedStorePersistsAcrossInstances() {
        let suite = "brewery-pinned-test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }

        let store = PinnedStore(defaults: defaults)
        XCTAssertTrue(store.isEmpty)

        store.toggle("cask:vlc")
        store.toggle("formula:wget")
        XCTAssertEqual(store.count, 2)
        XCTAssertTrue(store.isPinned("cask:vlc"))

        store.toggle("cask:vlc")
        XCTAssertFalse(store.isPinned("cask:vlc"))

        // A fresh instance reads what the first one wrote.
        let reloaded = PinnedStore(defaults: defaults)
        XCTAssertEqual(reloaded.ids, ["formula:wget"])
    }

    @MainActor
    func testPinnedStoreResolvesOnlyPackagesStillInTheCatalog() {
        let defaults = UserDefaults(suiteName: "brewery-pinned-resolve-\(UUID().uuidString)")!
        let store = PinnedStore(defaults: defaults)
        store.toggle("formula:wget")
        store.toggle("cask:gone-from-catalog")

        let catalog = [
            CatalogPackage(name: "wget", kind: .formula),
            CatalogPackage(name: "vlc", kind: .cask)
        ]
        XCTAssertEqual(store.pinned(in: catalog).map(\.name), ["wget"])
    }

    func testOutdatedFirstKeepsAlphabeticalOrderWithinEachGroup() {
        let packages = [
            BrewPackage(name: "a-fresh", kind: .formula),
            BrewPackage(name: "b-stale", kind: .formula, outdated: true),
            BrewPackage(name: "c-fresh", kind: .formula),
            BrewPackage(name: "d-stale", kind: .formula, outdated: true)
        ]

        XCTAssertEqual(packages.outdatedFirst().map(\.name), ["b-stale", "d-stale", "a-fresh", "c-fresh"])
        XCTAssertEqual([BrewPackage]().outdatedFirst(), [])
    }

    @MainActor
    func testNothingIsSelectedUntilTheUserPicksSomething() async {
        let store = PackageStore(service: MockBrewService())
        await store.refresh()

        // The info pane shows whenever there is a selection, so a refresh
        // must not invent one, and clearing it must stick.
        XCTAssertNil(store.selectedPackage)
        XCTAssertNil(store.selectedPackageID)

        store.selectedPackageID = PackageNodeID(kind: .formula, name: "wget").id
        XCTAssertEqual(store.selectedPackage?.name, "wget")

        store.selectedPackageID = nil
        XCTAssertNil(store.selectedPackage)
    }

    @MainActor
    func testLibraryListsEveryInstalledPackageOfBothKinds() async {
        let store = PackageStore(service: MockBrewService())
        await store.refresh()

        store.filter = .library
        XCTAssertEqual(store.filteredPackages.count, store.packages.count)
        XCTAssertTrue(store.filteredPackages.contains { $0.kind == .formula })
        XCTAssertTrue(store.filteredPackages.contains { $0.kind == .cask })

        store.searchText = "wget"
        XCTAssertEqual(store.filteredPackages.map(\.name), ["wget"])
    }

    @MainActor
    func testSelectingAPackageSwitchesToTheViewThatListsIt() async {
        let store = PackageStore(service: MockBrewService())
        await store.refresh()
        XCTAssertEqual(store.filter, .browse, "the catalog is the landing page")

        // Following a dependency link from Browse lands in the Library,
        // whichever kind the package is.
        store.selectPackage(PackageNodeID(kind: .formula, name: "wget"))
        XCTAssertEqual(store.filter, .library)
        XCTAssertEqual(store.selectedPackage?.name, "wget")

        store.filter = .browse
        store.selectPackage(PackageNodeID(kind: .cask, name: "visual-studio-code"))
        XCTAssertEqual(store.filter, .library)
        XCTAssertEqual(store.selectedPackage?.name, "visual-studio-code")

        // An unknown node changes nothing.
        store.filter = .browse
        store.selectPackage(PackageNodeID(kind: .formula, name: "not-installed"))
        XCTAssertEqual(store.filter, .browse)
    }

    @MainActor
    func testPackageStoreExposesDependencyGraph() async {
        let store = PackageStore(service: MockBrewService())
        await store.refresh()

        let wget = try! XCTUnwrap(store.packages.first { $0.name == "wget" })

        XCTAssertEqual(store.directDependencies(for: wget), [PackageNodeID(kind: .formula, name: "openssl@3")])
        XCTAssertTrue(store.directDependents(for: wget).isEmpty)
    }

    func testCaskArtifactsIgnoreShapesThatCarryNoAppBundle() throws {
        let decoder = JSONDecoder()

        // Homebrew's real shapes: a pkg cask, an app whose entry is an object,
        // and an interpolated path that cannot be resolved without brew.
        let pkgOnly = Data(#"[{"pkg": ["Installer.pkg"]}, {"uninstall": [{"pkgutil": "com.example"}]}]"#.utf8)
        XCTAssertNil(try decoder.decode(CaskArtifacts.self, from: pkgOnly).appBundleName)

        let objectEntry = Data(#"[{"app": [{"target": "Bitcoin Core.app"}]}]"#.utf8)
        XCTAssertEqual(try decoder.decode(CaskArtifacts.self, from: objectEntry).appBundleName, "Bitcoin Core.app")

        let interpolated = Data(#"[{"app": ["$APPDIR/Nested.app"]}]"#.utf8)
        XCTAssertNil(try decoder.decode(CaskArtifacts.self, from: interpolated).appBundleName)

        let pathTarget = Data(#"[{"app": ["/Applications/Firefox.app"]}]"#.utf8)
        XCTAssertEqual(try decoder.decode(CaskArtifacts.self, from: pathTarget).appBundleName, "Firefox.app")

        let empty = Data("[]".utf8)
        XCTAssertNil(try decoder.decode(CaskArtifacts.self, from: empty).appBundleName)
    }

    func testCatalogPackageRoundTripsAppBundleNameThroughTheCache() throws {
        let package = CatalogPackage(
            name: "vlc",
            kind: .cask,
            homepage: URL(string: "https://www.videolan.org/vlc/"),
            appBundleName: "VLC.app"
        )

        let snapshot = CatalogSnapshot(fetchedAt: Date(timeIntervalSince1970: 0), packages: [package])
        let decoded = try JSONDecoder().decode(CatalogSnapshot.self, from: JSONEncoder().encode(snapshot))

        XCTAssertEqual(decoded.packages.first?.appBundleName, "VLC.app")
    }

    func testIconSourcesPreferAnInstalledAppBundle() throws {
        let root = try makeTemporaryDirectory()
        let applications = root.appendingPathComponent("Applications", isDirectory: true)
        let bundle = applications.appendingPathComponent("VLC.app", isDirectory: true)
        try FileManager.default.createDirectory(at: bundle, withIntermediateDirectories: true)

        let homepage = URL(string: "https://www.videolan.org/vlc/")

        XCTAssertEqual(
            PackageIconResolver.sources(
                kind: .cask,
                token: "vlc",
                appBundleName: "VLC.app",
                homepage: homepage,
                applicationDirectories: [applications],
                caskroomDirectories: []
            ),
            [.appBundle(bundle)]
        )

        // Not on disk: the homepage candidates are used instead.
        let remote = PackageIconResolver.sources(
            kind: .cask,
            token: "vlc",
            appBundleName: "Missing.app",
            homepage: homepage,
            applicationDirectories: [applications],
            caskroomDirectories: []
        )
        XCTAssertEqual(remote, [
            .remote(URL(string: "https://www.videolan.org/apple-touch-icon.png")!),
            .remote(URL(string: "https://www.videolan.org/favicon.ico")!),
            .remote(URL(string: "https://icons.duckduckgo.com/ip3/www.videolan.org.ico")!)
        ])
    }

    func testCaskroomBeatsTheNameTheCaskDeclaresToday() throws {
        // bartender ships "Bartender 5.app", but the cask now declares
        // "Bartender 7.app". The Caskroom symlink still points at what is
        // installed, and that is the icon the user expects to see.
        let root = try makeTemporaryDirectory()
        let applications = root.appendingPathComponent("Applications", isDirectory: true)
        let installed = applications.appendingPathComponent("Bartender 5.app", isDirectory: true)
        try FileManager.default.createDirectory(at: installed, withIntermediateDirectories: true)

        let caskroom = root.appendingPathComponent("Caskroom", isDirectory: true)
        let versionDirectory = caskroom
            .appendingPathComponent("bartender", isDirectory: true)
            .appendingPathComponent("5.2.4", isDirectory: true)
        try FileManager.default.createDirectory(at: versionDirectory, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(
            at: versionDirectory.appendingPathComponent("Bartender 5.app"),
            withDestinationURL: installed
        )

        let sources = PackageIconResolver.sources(
            kind: .cask,
            token: "bartender",
            appBundleName: "Bartender 7.app",
            homepage: URL(string: "https://www.macbartender.com/"),
            applicationDirectories: [applications],
            caskroomDirectories: [caskroom]
        )

        XCTAssertEqual(sources, [.appBundle(installed.resolvingSymlinksInPath())])
    }

    func testCaskroomLinkPointingAtADeletedAppIsIgnored() throws {
        let root = try makeTemporaryDirectory()
        let caskroom = root.appendingPathComponent("Caskroom", isDirectory: true)
        let versionDirectory = caskroom
            .appendingPathComponent("ghost", isDirectory: true)
            .appendingPathComponent("1.0", isDirectory: true)
        try FileManager.default.createDirectory(at: versionDirectory, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(
            at: versionDirectory.appendingPathComponent("Ghost.app"),
            withDestinationURL: root.appendingPathComponent("Applications/Ghost.app")
        )

        XCTAssertNil(PackageIconResolver.installedAppBundleURL(token: "ghost", in: [caskroom]))
    }

    func testCaskroomDirectoryIsDerivedFromTheDetectedBrewPath() {
        XCTAssertEqual(
            PackageIconResolver.caskroomDirectory(forBrewAt: URL(fileURLWithPath: "/opt/homebrew/bin/brew")).path,
            "/opt/homebrew/Caskroom"
        )
        XCTAssertEqual(
            PackageIconResolver.caskroomDirectory(forBrewAt: URL(fileURLWithPath: "/Users/me/brew/bin/brew")).path,
            "/Users/me/brew/Caskroom"
        )
    }

    func testIconSourcesSkipFormulaeAndUnusableHomepages() {
        // Formulae are command line tools, and keep their glyph.
        XCTAssertTrue(PackageIconResolver.sources(
            kind: .formula,
            token: "wget",
            appBundleName: nil,
            homepage: URL(string: "https://www.gnu.org/software/wget/")
        ).isEmpty)

        XCTAssertTrue(PackageIconResolver.remoteIconCandidates(homepage: nil).isEmpty)
        XCTAssertTrue(PackageIconResolver.remoteIconCandidates(homepage: URL(string: "ftp://example.com/x")).isEmpty)
        XCTAssertTrue(PackageIconResolver.remoteIconCandidates(homepage: URL(fileURLWithPath: "/tmp/x")).isEmpty)
    }

    func testGitHubHomepagesResolveToTheOwnerAvatarNotTheOctocat() {
        // codex lives at github.com/openai/codex; the Octocat misrepresents it,
        // OpenAI's avatar is the publisher's logo.
        XCTAssertEqual(
            PackageIconResolver.remoteIconCandidates(homepage: URL(string: "https://github.com/openai/codex")),
            [URL(string: "https://github.com/openai.png?size=128")!]
        )
        XCTAssertEqual(
            PackageIconResolver.remoteIconCandidates(homepage: URL(string: "https://www.github.com/Sequel-Ace/Sequel-Ace/")),
            [URL(string: "https://github.com/Sequel-Ace.png?size=128")!]
        )
        // Site features are not owners.
        XCTAssertTrue(PackageIconResolver.remoteIconCandidates(homepage: URL(string: "https://github.com/topics/editor")).isEmpty)
        XCTAssertTrue(PackageIconResolver.remoteIconCandidates(homepage: URL(string: "https://github.com/")).isEmpty)
    }

    func testSharedHostsYieldNoIconRatherThanTheHostsOwn() {
        for homepage in [
            "https://sourceforge.net/projects/handbrake/",
            "https://gitlab.com/inkscape/inkscape",
            "https://fonts.google.com/specimen/Inter",
            "https://pypi.org/project/black/"
        ] {
            XCTAssertTrue(
                PackageIconResolver.remoteIconCandidates(homepage: URL(string: homepage)).isEmpty,
                "\(homepage) should not borrow its host's favicon"
            )
        }

        // A vendor's own domain still resolves, and GitHub's own docs are
        // GitHub's product, so the GitHub favicon is truthful there.
        XCTAssertFalse(PackageIconResolver.remoteIconCandidates(homepage: URL(string: "https://iterm2.com/")).isEmpty)
        XCTAssertFalse(PackageIconResolver.remoteIconCandidates(homepage: URL(string: "https://docs.github.com/en/copilot")).isEmpty)
    }

    func testFontCasksNeverLookForAnIcon() {
        XCTAssertTrue(PackageIconResolver.isFont(token: "font-hack-nerd-font"))
        XCTAssertFalse(PackageIconResolver.isFont(token: "fontforge"))

        let sources = PackageIconResolver.sources(
            kind: .cask,
            token: "font-hack-nerd-font",
            appBundleName: nil,
            homepage: URL(string: "https://github.com/ryanoasis/nerd-fonts"),
            caskroomDirectories: []
        )
        XCTAssertTrue(sources.isEmpty)
    }

    func testIconCacheDirectoryIsVersionedAndKnowsItsPredecessors() {
        let current = IconDiskCache.defaultDirectory()
        XCTAssertTrue(current.lastPathComponent.hasSuffix("-v\(IconDiskCache.formatVersion)"))

        let legacy = IconDiskCache.legacyDirectories()
        XCTAssertTrue(legacy.contains { $0.lastPathComponent == "IconCache" })
        XCTAssertFalse(legacy.contains(current))
    }

    func testLocalAppBundleLookupRejectsPathTraversal() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        XCTAssertNil(PackageIconResolver.localAppBundleURL(forBundleNamed: "../Firefox.app", in: [directory]))
        XCTAssertNil(PackageIconResolver.localAppBundleURL(forBundleNamed: "", in: [directory]))
        XCTAssertNil(PackageIconResolver.installedAppBundleURL(token: "../../etc", in: [directory]))
        XCTAssertNil(PackageIconResolver.installedAppBundleURL(token: "", in: [directory]))
    }

    func testIconCacheFileNamesDoNotCollideAcrossTokens() {
        // Both sanitize to "cask-1password-7" before the hash is appended.
        let first = IconDiskCache.sanitize("cask:1password@7")
        let second = IconDiskCache.sanitize("cask:1password-7")

        XCTAssertNotEqual(first, second)
        XCTAssertFalse(first.contains(":"))
        XCTAssertFalse(first.contains("@"))
        // Stable across launches, or a cached icon is never found again.
        XCTAssertEqual(first, IconDiskCache.sanitize("cask:1password@7"))
    }

    func testIconCacheDistinguishesHitsMissesAndExpiry() throws {
        let directory = try makeTemporaryDirectory()
        let cache = IconDiskCache(directory: directory, hitLifetime: 60, missLifetime: 60)

        XCTAssertEqual(cache.load("cask:vlc"), .absent)

        cache.store(Data([0x1, 0x2, 0x3]), for: "cask:vlc")
        XCTAssertEqual(cache.load("cask:vlc"), .hit(Data([0x1, 0x2, 0x3])))

        cache.storeMiss(for: "cask:ghost")
        XCTAssertEqual(cache.load("cask:ghost"), .miss)

        // Past its lifetime a miss is retried rather than honoured forever.
        let expired = IconDiskCache(directory: directory, hitLifetime: 60, missLifetime: 60)
        try FileManager.default.setAttributes(
            [.modificationDate: Date(timeIntervalSinceNow: -120)],
            ofItemAtPath: expired.fileURL(for: "cask:ghost").path
        )
        XCTAssertEqual(expired.load("cask:ghost"), .absent)
    }

    func testIconValidatorRejectsNonImagesAndTinyImages() throws {
        XCTAssertFalse(IconValidator.isUsableIcon(Data()))
        // A 200 response carrying an error page is the common favicon failure.
        XCTAssertFalse(IconValidator.isUsableIcon(Data("<!doctype html><html></html>".utf8)))

        XCTAssertTrue(IconValidator.isUsableIcon(try pngData(side: 64)))
        XCTAssertFalse(IconValidator.isUsableIcon(try pngData(side: 8)))
    }

    private func pngData(side: Int) throws -> Data {
        let context = try XCTUnwrap(CGContext(
            data: nil,
            width: side,
            height: side,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: side, height: side))

        let image = try XCTUnwrap(context.makeImage())
        let output = NSMutableData()
        let destination = try XCTUnwrap(
            CGImageDestinationCreateWithData(output, "public.png" as CFString, 1, nil)
        )
        CGImageDestinationAddImage(destination, image, nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        return output as Data
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("brewery-icon-test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
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

private struct MockCatalogFetcher: CatalogFetching {
    struct NotStubbed: Error {}

    var payloads: [URL: Data] = [:]
    var error: Error?

    func data(from url: URL) async throws -> Data {
        if let error {
            throw error
        }
        // A URL the test did not stub stands in for a request that failed,
        // which is what analytics does when brew.sh is unreachable.
        guard let payload = payloads[url] else { throw NotStubbed() }
        return payload
    }
}
