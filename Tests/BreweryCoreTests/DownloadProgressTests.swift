import XCTest
@testable import BreweryCore

final class DownloadProgressTests: XCTestCase {

    // MARK: - Parser

    func testParserBuffersALineSplitAcrossChunks() {
        var parser = BrewProgressParser()

        XCTAssertEqual(parser.consume("==> Fetching wg"), [])
        XCTAssertEqual(parser.consume("et\n"), [.fetching(name: "wget")])
    }

    func testParserReadsProgressFromCarriageReturnRedraws() {
        var parser = BrewProgressParser()

        XCTAssertEqual(
            parser.consume("==> Downloading https://example.test/vlc.dmg\r  42."),
            [.downloading(name: nil, detail: "vlc.dmg")]
        )
        XCTAssertEqual(parser.consume("3%\r"), [.progress(0.423)])
        XCTAssertEqual(parser.consume("100.0%\r"), [.progress(1)])
    }

    func testParserFollowsACaskFromFetchToSuccess() {
        var parser = BrewProgressParser()

        let events = parser.consume("""
        ==> Fetching visual-studio-code
        ==> Downloading https://update.example.test/stable/vscode.zip
        ==> Installing Cask visual-studio-code
        🍺  visual-studio-code was successfully installed!

        """)

        XCTAssertEqual(events, [
            .fetching(name: "visual-studio-code"),
            .downloading(name: "visual-studio-code", detail: "vscode.zip"),
            .installing(name: "visual-studio-code"),
            .finished(name: "visual-studio-code")
        ])
    }

    func testParserFollowsAFormulaBottleToItsCellarSummary() {
        var parser = BrewProgressParser()

        let events = parser.consume("""
        ==> Fetching wget
        ==> Downloading https://ghcr.io/v2/homebrew/core/wget/blobs/sha256:abcd
        ==> Pouring wget--1.25.0.arm64_sequoia.bottle.tar.gz
        🍺  /opt/homebrew/Cellar/wget/1.25.0: 20 files, 3.8MB

        """)

        XCTAssertEqual(events, [
            .fetching(name: "wget"),
            .downloading(name: "wget", detail: "wget"),
            .installing(name: "wget"),
            .finished(name: "wget")
        ])
    }

    func testParserTurnsAnErrorIntoAFailure() {
        var parser = BrewProgressParser()

        XCTAssertEqual(
            parser.consume("Error: No available formula with the name \"nope\".\n"),
            [.failed(message: "No available formula with the name \"nope\".")]
        )
    }

    func testParserEmitsOnePackageAtATimeInAnUpgrade() {
        var parser = BrewProgressParser()

        let events = parser.consume("""
        ==> Upgrading wget 1.24.5 -> 1.25.0
        ==> Upgrading vim 9.0 -> 9.1

        """)

        XCTAssertEqual(events, [
            .installing(name: "wget"),
            .installing(name: "vim")
        ])
    }

    func testParserAttributesADependencyFetchToItsTarget() {
        var parser = BrewProgressParser()

        XCTAssertEqual(
            parser.consume("==> Fetching dependencies for wget: openssl@3\n"),
            [.fetching(name: "wget")]
        )
    }

    func testParserIgnoresOutputThatNamesNoPackage() {
        var parser = BrewProgressParser()

        let events = parser.consume("""
        Warning: wget 1.24.5 is already installed
        Already downloaded: /Users/someone/Library/Caches/Homebrew/downloads/wget.tar.gz
        ==> Upgrading 3 outdated packages
        ==> Running `brew cleanup wget`...

        """)

        XCTAssertEqual(events, [])
    }

    // MARK: - Session

    func testSessionSeedsOneItemPerTarget() {
        let session = DownloadSession(action: .upgradeAll(names: ["wget", "vim"], kind: .formula))

        XCTAssertEqual(session.items.map(\.name), ["wget", "vim"])
        XCTAssertEqual(session.items.map(\.kind), [.formula, .formula])
        XCTAssertEqual(session.items.map(\.phase), [.queued, .queued])
        XCTAssertFalse(session.isRunning)
        XCTAssertEqual(session.activeCount, 2)
    }

    func testSessionSeedsASingleRowForCleanup() {
        let session = DownloadSession(action: .cleanup)

        XCTAssertEqual(session.items.count, 1)
        XCTAssertEqual(session.items.first?.name, "Clean Up Homebrew")
        XCTAssertNil(session.items.first?.kind)
    }

    func testSessionMovesThroughPhasesAndAdvancesToTheNextPackage() {
        var session = DownloadSession(action: .upgradeAll(names: ["wget", "vim"], kind: .formula))
        session.activate(session.items.map(\.id))

        XCTAssertEqual(session.activeItem?.name, "wget")
        XCTAssertEqual(session.items[0].phase, .fetching)

        session.apply(.downloading(name: "wget", detail: "wget.tar.gz"))
        session.apply(.progress(0.5))
        XCTAssertEqual(session.items[0].phase, .downloading)
        XCTAssertEqual(session.items[0].statusText, "Downloading 50%")

        session.apply(.installing(name: "wget"))
        XCTAssertEqual(session.items[0].phase, .installing)

        session.apply(.finished(name: "wget"))
        XCTAssertEqual(session.items[0].phase, .finished)
        XCTAssertEqual(session.activeItem?.name, "vim")
        XCTAssertEqual(session.items[1].phase, .fetching)
    }

    func testSessionAggregateFractionCountsSettledItemsWhole() {
        var session = DownloadSession(action: .upgradeAll(names: ["wget", "vim"], kind: .formula))
        session.activate(session.items.map(\.id))

        session.apply(.finished(name: "wget"))
        session.apply(.downloading(name: "vim", detail: nil))
        session.apply(.progress(0.5))

        XCTAssertEqual(session.fraction, 0.75, accuracy: 0.0001)
    }

    func testSessionFailureSettlesOnlyTheFailingAction() {
        var session = DownloadSession(action: .install(name: "vlc", kind: .cask))
        session.append(action: .install(name: "wget", kind: .formula))
        let firstIDs = Array(session.items.prefix(1)).map(\.id)
        let secondIDs = Array(session.items.suffix(1)).map(\.id)

        session.activate(firstIDs)
        session.apply(.downloading(name: "vlc", detail: "vlc.dmg"))
        session.settleActiveAction(succeeded: false, message: "curl: (22) The requested URL returned error: 404")

        XCTAssertEqual(session.items[0].phase, .failed)
        XCTAssertEqual(session.items[1].phase, .queued, "the queued action is not the one that failed")
        XCTAssertTrue(session.hasFailure)

        session.activate(secondIDs)
        session.settleActiveAction(succeeded: true, message: nil)

        XCTAssertEqual(session.items[1].phase, .finished)
        XCTAssertTrue(session.hasFailure, "the failure stays on screen until dismissed")
    }

    func testSessionIgnoresLateOutputAfterSettling() {
        var session = DownloadSession(action: .install(name: "vlc", kind: .cask))
        session.activate(session.items.map(\.id))
        session.apply(.downloading(name: "vlc", detail: nil))
        session.settleActiveAction(succeeded: true, message: nil)

        session.apply(.downloading(name: "vlc", detail: "late.dmg"))

        XCTAssertEqual(session.items[0].phase, .finished)
        XCTAssertNil(session.currentItemID)
        XCTAssertTrue(session.isLingering)
    }

    func testSessionRemovesOnlyQueuedItems() {
        var session = DownloadSession(action: .install(name: "vlc", kind: .cask))
        let queued = session.append(action: .install(name: "wget", kind: .formula))
        session.activate(Array(session.items.prefix(1)).map(\.id))

        session.remove(itemsWith: Set(queued))
        XCTAssertEqual(session.items.map(\.name), ["vlc"])

        // The running item is never removable this way.
        session.remove(itemsWith: Set(session.items.map(\.id)))
        XCTAssertEqual(session.items.map(\.name), ["vlc"])
    }

    // MARK: - CommandRunner decoding

    func testUTF8DecoderCarriesAScalarSplitAcrossChunks() {
        let data = Data("a🍺b".utf8)
        var decoder = UTF8StreamDecoder()

        // Cut inside the four-byte emoji.
        let first = decoder.decode(Data(data.prefix(3)))
        let second = decoder.decode(Data(data.dropFirst(3)))

        XCTAssertEqual(first, "a")
        XCTAssertEqual(second, "🍺b")
        XCTAssertEqual(first + second, "a🍺b")
    }

    func testUTF8DecoderFlushesAnIncompleteTail() {
        let data = Data("🍺".utf8)
        var decoder = UTF8StreamDecoder()

        XCTAssertEqual(decoder.decode(Data(data.prefix(2))), "")
        XCTAssertEqual(decoder.decode(Data(), flushing: true), "\u{FFFD}")
    }

    // MARK: - PackageStore

    @MainActor
    func testSuccessfulActionSettlesTheSessionAndRefreshesInventory() async {
        let service = ScriptedBrewService()
        let action = BrewAction.install(name: "vlc", kind: .cask)
        service.scripts[action.id] = [
            "==> Fetching vlc\n",
            "==> Downloading https://example.test/vlc.dmg\n",
            "==> Installing Cask vlc\n",
            "🍺  vlc was successfully installed!\n"
        ]
        let store = PackageStore(service: service, downloadLinger: 60)

        await store.perform(action)

        XCTAssertEqual(store.statusMessage, "Finished \(action.commandDisplay)")
        XCTAssertEqual(store.downloads?.items.map(\.phase), [.finished])
        XCTAssertEqual(store.downloads?.items.first?.name, "vlc")
        XCTAssertTrue(store.queuedActions.isEmpty)
    }

    @MainActor
    func testFailedActionMarksTheItemFailedAndLetsTheQueueContinue() async {
        let service = ScriptedBrewService()
        let failing = BrewAction.install(name: "missing", kind: .formula)
        let next = BrewAction.install(name: "wget", kind: .formula)
        service.scripts[failing.id] = ["Error: No available formula with the name \"missing\".\n"]
        service.exitCodes[failing.id] = 1
        let store = PackageStore(service: service, downloadLinger: 60)

        let running = Task { await store.perform(failing) }
        await waitUntil { store.isRunningCommand }
        await store.perform(next)
        await running.value

        XCTAssertEqual(service.startedActions.map(\.id), [failing.id, next.id])
        XCTAssertEqual(store.downloads?.items.map(\.phase), [.failed, .finished])
        XCTAssertEqual(store.downloads?.items.first?.phase, .failed)
        XCTAssertTrue(store.downloads?.hasFailure == true)
        XCTAssertEqual(store.statusMessage, "Finished \(next.commandDisplay)")
    }

    @MainActor
    func testSecondPerformWhileBusyQueuesThenRunsInOrder() async {
        let service = ScriptedBrewService()
        let first = BrewAction.install(name: "vlc", kind: .cask)
        let second = BrewAction.install(name: "wget", kind: .formula)
        service.scripts[first.id] = ["==> Downloading https://example.test/vlc.dmg\n"]
        service.actionDelay = 0.05
        let store = PackageStore(service: service, downloadLinger: 60)

        let running = Task { await store.perform(first) }
        await waitUntil { store.isRunningCommand }
        await store.perform(second)

        XCTAssertEqual(store.queuedActions.map(\.id), [second.id])
        XCTAssertEqual(store.downloads?.items.map(\.name), ["vlc", "wget"])

        await running.value

        XCTAssertEqual(service.startedActions.map(\.id), [first.id, second.id])
        XCTAssertTrue(store.queuedActions.isEmpty)
        XCTAssertEqual(store.downloads?.items.map(\.phase), [.finished, .finished])
    }

    @MainActor
    func testDuplicateQueuedActionIsIgnored() async {
        let service = ScriptedBrewService()
        let first = BrewAction.install(name: "vlc", kind: .cask)
        let second = BrewAction.install(name: "wget", kind: .formula)
        service.actionDelay = 0.05
        let store = PackageStore(service: service, downloadLinger: 60)

        let running = Task { await store.perform(first) }
        await waitUntil { store.isRunningCommand }
        await store.perform(second)
        await store.perform(second)

        XCTAssertEqual(store.queuedActions.count, 1)
        XCTAssertEqual(store.downloads?.items.count, 2)
        await running.value
    }

    @MainActor
    func testClearQueuedActionsLeavesTheRunningItem() async {
        let service = ScriptedBrewService()
        let first = BrewAction.install(name: "vlc", kind: .cask)
        let second = BrewAction.install(name: "wget", kind: .formula)
        service.actionDelay = 0.05
        let store = PackageStore(service: service, downloadLinger: 60)

        let running = Task { await store.perform(first) }
        await waitUntil { store.isRunningCommand }
        await store.perform(second)

        store.clearQueuedActions()

        XCTAssertTrue(store.queuedActions.isEmpty)
        XCTAssertEqual(store.downloads?.items.map(\.name), ["vlc"])
        XCTAssertEqual(store.downloads?.items.first?.phase.isSettled, false)
        await running.value

        XCTAssertEqual(service.startedActions.map(\.id), [first.id])
    }

    @MainActor
    func testCancelQueuedItemRemovesItsAction() async {
        let service = ScriptedBrewService()
        let first = BrewAction.install(name: "vlc", kind: .cask)
        let second = BrewAction.install(name: "wget", kind: .formula)
        service.actionDelay = 0.05
        let store = PackageStore(service: service, downloadLinger: 60)

        let running = Task { await store.perform(first) }
        await waitUntil { store.isRunningCommand }
        await store.perform(second)
        let queuedItem = try! XCTUnwrap(store.downloads?.items.last)

        store.cancelQueuedItem(queuedItem.id)

        XCTAssertTrue(store.queuedActions.isEmpty)
        XCTAssertEqual(store.downloads?.items.map(\.name), ["vlc"])
        await running.value
    }

    @MainActor
    func testFinishedSessionLingersThenClears() async {
        let service = ScriptedBrewService()
        let store = PackageStore(service: service, downloadLinger: 0.05)

        await store.perform(.install(name: "wget", kind: .formula))
        XCTAssertNotNil(store.downloads, "the finished run stays on screen briefly")

        try? await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertNil(store.downloads)
    }

    @MainActor
    func testAQueuedRunSurvivesThePreviousSessionsTimer() async {
        let service = ScriptedBrewService()
        let first = BrewAction.install(name: "vlc", kind: .cask)
        let second = BrewAction.install(name: "wget", kind: .formula)
        service.refreshDelay = 0.4
        let store = PackageStore(service: service, downloadLinger: 0.08)

        await store.perform(first)
        XCTAssertEqual(store.downloads?.items.map(\.name), ["vlc"])

        // A refresh is running, so the next action queues; queueing replaces
        // the lingering session without cancelling its timer.
        let refresh = Task { await store.refresh() }
        await waitUntil { store.isRunningCommand }
        await store.perform(second)
        XCTAssertEqual(store.downloads?.items.map(\.name), ["wget"])

        // The old session's timer has fired by now and must leave the new one
        // alone even though it is not running yet.
        try? await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(store.downloads?.items.map(\.name), ["wget"])

        await refresh.value
        XCTAssertEqual(service.startedActions.map(\.id), [first.id, second.id])
    }

    @MainActor
    func testHasLoadedInventoryFlipsAfterRefresh() async {
        let store = PackageStore(service: MockBrewService())
        XCTAssertFalse(store.hasLoadedInventory)

        await store.refresh()
        XCTAssertTrue(store.hasLoadedInventory)

        let missing = PackageStore(service: MockBrewService(brewAvailable: false))
        await missing.refresh()
        XCTAssertTrue(missing.hasLoadedInventory, "a missing Homebrew also counts as loaded, not loading")
    }

    // MARK: - CatalogStore

    @MainActor
    func testCatalogHasLoadedOnceFlipsOnSuccessAndOnFailure() async {
        let successURL = URL(string: "https://example.test/formula.json")!
        let emptyURL = URL(string: "https://example.test/cask.json")!
        let success = CatalogStore(
            fetcher: StubCatalogFetcher(data: Data("[]".utf8)),
            cacheURL: temporaryCacheURL(),
            formulaURL: successURL,
            caskURL: emptyURL
        )
        XCTAssertFalse(success.hasLoadedOnce)

        await success.load(installedPackages: [], forceRefresh: true)
        XCTAssertTrue(success.hasLoadedOnce)

        let failure = CatalogStore(
            fetcher: StubCatalogFetcher(error: CatalogError.httpStatus(500)),
            cacheURL: temporaryCacheURL(),
            formulaURL: successURL,
            caskURL: emptyURL
        )
        await failure.load(installedPackages: [], forceRefresh: true)
        XCTAssertTrue(failure.hasLoadedOnce, "a failed load is still a load: the page stops showing skeletons")
    }

    // MARK: - Helpers

    @MainActor
    private func waitUntil(
        timeout: TimeInterval = 2,
        _ predicate: () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !predicate(), Date() < deadline {
            await Task.yield()
        }
        XCTAssertTrue(predicate(), "condition did not become true within \(timeout)s")
    }

    private func temporaryCacheURL() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("brewery-download-test-\(UUID().uuidString).json")
    }
}

// MARK: - Test doubles

/// Serves scripted Homebrew output for one action, and can make a refresh take
/// long enough for a second action to be queued behind it.
private final class ScriptedBrewService: BrewServicing {
    private let inner = MockBrewService()

    /// Action id → the lines its command prints.
    var scripts: [BrewAction.ID: [String]] = [:]
    var exitCodes: [BrewAction.ID: Int32] = [:]
    var actionDelay: TimeInterval = 0
    var refreshDelay: TimeInterval = 0
    private(set) var startedActions: [BrewAction] = []

    var detectionReport: BrewDetectionReport { inner.detectionReport }
    var brewPath: URL? { inner.brewPath }

    func refreshInventory(onOutput: @escaping @Sendable (CommandLogEntry.Stream, String) -> Void) async throws -> BrewInventory {
        if refreshDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(refreshDelay * 1_000_000_000))
        }
        return try await inner.refreshInventory(onOutput: onOutput)
    }

    func refreshPackages(onOutput: @escaping @Sendable (CommandLogEntry.Stream, String) -> Void) async throws -> [BrewPackage] {
        try await refreshInventory(onOutput: onOutput).packages
    }

    func diagnostics(onOutput: @escaping @Sendable (CommandLogEntry.Stream, String) -> Void) async throws -> BrewDiagnostics {
        try await inner.diagnostics(onOutput: onOutput)
    }

    func runAction(
        _ action: BrewAction,
        onOutput: @escaping @Sendable (CommandLogEntry.Stream, String) -> Void,
        onPasswordRequest: @escaping SudoPasswordHandler
    ) async throws -> CommandResult {
        startedActions.append(action)
        if actionDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(actionDelay * 1_000_000_000))
        }
        for line in scripts[action.id] ?? [] {
            onOutput(.stdout, line)
        }
        return CommandResult(
            commandDisplay: action.commandDisplay,
            stdout: "",
            stderr: exitCodes[action.id].map { "brew exited with code \($0)" } ?? "",
            exitCode: exitCodes[action.id] ?? 0,
            startedAt: Date(),
            finishedAt: Date()
        )
    }
}

private struct StubCatalogFetcher: CatalogFetching {
    var data: Data?
    var error: Error?

    init(data: Data) {
        self.data = data
    }

    init(error: Error) {
        self.error = error
    }

    func data(from url: URL) async throws -> Data {
        if let error { throw error }
        return data ?? Data("[]".utf8)
    }
}
