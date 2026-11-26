import Combine
import Foundation

/// sudo waiting on the user for an administrator password while an action
/// runs.
public struct PasswordRequest: Identifiable, Equatable {
    public enum Notice: Equatable {
        /// sudo asked again from the same process: the last password was wrong.
        case wrongPassword
        /// sudo turned down the saved password, so it was forgotten.
        case savedPasswordRejected
        /// Touch ID can no longer unlock the saved password, so it was
        /// forgotten. The command log says why.
        case savedPasswordUnreadable
    }

    public let id = UUID()
    public let actionTitle: String
    public let notice: Notice?
    /// Whether the sheet can offer Touch ID on this Mac.
    public let offersTouchID: Bool
    /// Where the Touch ID checkbox starts.
    public let usesTouchID: Bool
    let sudoProcessID: Int32?
    /// This sudo already turned down a password.
    let isRetry: Bool
}

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
    @Published public private(set) var passwordRequest: PasswordRequest?
    @Published public private(set) var hasSavedPassword = false
    /// The run in progress, or the one still on screen after it ended.
    @Published public private(set) var downloads: DownloadSession?
    /// Actions waiting for the one running now to finish, in order.
    @Published public private(set) var queuedActions: [BrewAction] = []
    /// Set once an inventory load has been attempted, so the Library can tell
    /// "nothing installed" from "not loaded yet".
    @Published public private(set) var hasLoadedInventory = false
    /// How this Mac's `sudo` will authenticate, so the UI can explain why a
    /// password sheet may be replaced by Touch ID or a smartcard.
    @Published public private(set) var sudoAuthentication: SudoPAMReport

    public let service: BrewServicing
    private let passwordVault: PasswordVaulting
    /// How long a finished session stays on screen when nothing failed.
    private let downloadLingerNanoseconds: UInt64

    private struct PasswordAnswer {
        let sudoProcessID: Int32?
        let password: String
        let fromTouchID: Bool
    }

    private struct PendingSave {
        let password: String
        /// sudo's first try at this password: a wrong first try always
        /// draws a retry, so if none came, sudo took it.
        let isFirstTry: Bool
    }

    private var isAnsweringPasswords = false
    private var isAskingForPassword = false
    /// Bumped when an action's prompts end, so a Touch ID prompt still open
    /// from that action cannot touch the next one's state.
    private var passwordEpoch = 0
    private var passwordContinuation: CheckedContinuation<String?, Never>?
    private var lastAnswer: PasswordAnswer?
    /// The Touch ID checkbox as last left during this action.
    private var wantsTouchID: Bool?
    /// Kept for Touch ID once sudo has evidently taken it, so a wrong
    /// password is never saved.
    private var passwordToSave: PendingSave?

    // MARK: Download queue state

    /// Session items belonging to each action, kept while the action waits.
    private var itemIDsByAction: [BrewAction.ID: [DownloadItem.ID]] = [:]
    /// The action whose command is running now.
    private var currentAction: BrewAction?
    private var isDraining = false
    /// Feeds Homebrew's output into the session for the action running now.
    private var progressParser = BrewProgressParser()
    private var sessionClearTask: Task<Void, Never>?
    /// Bumped whenever a session is replaced, so an old linger timer cannot
    /// clear a session it does not belong to.
    private var sessionRevision = 0

    public init(
        service: BrewServicing = LiveBrewService(),
        passwordVault: PasswordVaulting = SecureEnclavePasswordVault(),
        downloadLinger: TimeInterval = 8,
        sudoAuthentication: SudoPAMReport = SudoPAMInspector().inspect()
    ) {
        self.service = service
        self.passwordVault = passwordVault
        self.downloadLingerNanoseconds = UInt64(max(downloadLinger, 0) * 1_000_000_000)
        self.sudoAuthentication = sudoAuthentication
        hasSavedPassword = passwordVault.hasSavedPassword
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
            hasLoadedInventory = true
            return
        }

        await runTrackedCommand(status: "Refreshing packages") { [self] in
            let inventory = try await self.service.refreshInventory(onOutput: self.makeLogSink())
            self.packages = inventory.packages
            self.dependencyGraph = inventory.graph
            self.statusMessage = "Loaded \(inventory.packages.count) packages"
        }
        hasLoadedInventory = true
    }

    /// Runs an action now, or queues it behind the command already running.
    ///
    /// A queued call returns at once; the drain loop started by the running
    /// command picks it up in order and refreshes the inventory between
    /// actions, so the Library is current by the time the queue empties.
    public func perform(_ action: BrewAction) async {
        guard !isDraining, !isRunningCommand else {
            enqueue(action)
            return
        }

        // A run that has ended but is still on screen gives way to this one.
        if downloads?.isLingering == true {
            clearDownloadSession()
        }
        await drain(startingWith: action)
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

    /// Both answers name the request they belong to, so a late answer to a
    /// prompt that has already gone never lands on the next one.
    /// `rememberWithTouchID` is the sheet's checkbox, or nil when the sheet
    /// had no checkbox to show; then any saved password is left as it is.
    public func submitPassword(_ password: String, rememberWithTouchID: Bool?, for requestID: PasswordRequest.ID) {
        guard let request = passwordRequest, request.id == requestID else { return }
        lastAnswer = PasswordAnswer(sudoProcessID: request.sudoProcessID, password: password, fromTouchID: false)
        if let rememberWithTouchID {
            wantsTouchID = rememberWithTouchID
            passwordToSave = rememberWithTouchID ? PendingSave(password: password, isFirstTry: !request.isRetry) : nil
            if !rememberWithTouchID {
                forgetSavedPassword()
            }
        }
        resolvePasswordRequest(with: password)
    }

    public func forgetSavedPassword() {
        forgetSavedPassword(because: "Forgot your saved password\n")
    }

    public func cancelPasswordRequest(_ requestID: PasswordRequest.ID) {
        guard passwordRequest?.id == requestID else { return }
        appendLog(.status, "Password request cancelled\n")
        resolvePasswordRequest(with: nil)
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

    // MARK: - Downloads and the action queue

    /// Removes a finished or failed run from the popover and the Library.
    public func clearDownloadSession() {
        sessionClearTask?.cancel()
        sessionClearTask = nil
        downloads = nil
        itemIDsByAction.removeAll()
        sessionRevision += 1
    }

    /// Drops everything still waiting. The action running now is untouched.
    public func clearQueuedActions() {
        let removed = queuedActions
        queuedActions.removeAll()
        var ids = Set<DownloadItem.ID>()
        for action in removed {
            if let itemIDs = itemIDsByAction.removeValue(forKey: action.id) {
                ids.formUnion(itemIDs)
            }
        }
        downloads?.remove(itemsWith: ids)
        clearSessionIfEmpty()
    }

    public func cancelQueuedAction(_ action: BrewAction) {
        guard let index = queuedActions.firstIndex(where: { $0.id == action.id }) else { return }
        queuedActions.remove(at: index)
        if let itemIDs = itemIDsByAction.removeValue(forKey: action.id) {
            downloads?.remove(itemsWith: Set(itemIDs))
        }
        clearSessionIfEmpty()
    }

    /// A row of the popover cannot name the action it belongs to; the tracked
    /// item ids make the connection.
    public func cancelQueuedItem(_ itemID: DownloadItem.ID) {
        for (actionID, ids) in itemIDsByAction where ids.contains(itemID) {
            guard let action = queuedActions.first(where: { $0.id == actionID }) else { return }
            cancelQueuedAction(action)
            return
        }
    }

    private func clearSessionIfEmpty() {
        guard let session = downloads, session.items.isEmpty else { return }
        clearDownloadSession()
    }

    private func enqueue(_ action: BrewAction) {
        // Clicking the same button twice must not run the command twice.
        guard action.id != currentAction?.id,
              !queuedActions.contains(where: { $0.id == action.id }) else { return }
        queuedActions.append(action)
        itemIDsByAction[action.id] = seedSessionItems(for: action)
    }

    /// Adds an action to the session and returns its new item ids. A session
    /// left on screen from an earlier run is replaced, unless this queueing
    /// happened inside that run.
    private func seedSessionItems(for action: BrewAction) -> [DownloadItem.ID] {
        if downloads == nil || (downloads?.isLingering == true && !isDraining) {
            let session = DownloadSession(action: action)
            downloads = session
            sessionRevision += 1
            return session.items.map(\.id)
        }
        return downloads?.append(action: action) ?? []
    }

    private func drain(startingWith first: BrewAction) async {
        guard !isDraining else { return }
        isDraining = true
        defer {
            isDraining = false
            finishSession()
        }

        var pending: BrewAction? = first
        while true {
            let action: BrewAction
            if let pendingAction = pending {
                action = pendingAction
                pending = nil
            } else if !queuedActions.isEmpty {
                action = queuedActions.removeFirst()
            } else {
                break
            }
            await runAction(action)
        }
    }

    private func drainQueuedActions() async {
        guard !isDraining, !queuedActions.isEmpty else { return }
        isDraining = true
        defer {
            isDraining = false
            finishSession()
        }

        while !queuedActions.isEmpty {
            await runAction(queuedActions.removeFirst())
        }
    }

    private func runAction(_ action: BrewAction) async {
        currentAction = action
        defer { currentAction = nil }

        if sudoAuthentication.canPreemptPassword {
            appendLog(.status, sudoAuthentication.explanation + "\n")
        }

        let itemIDs = itemIDsByAction.removeValue(forKey: action.id) ?? seedSessionItems(for: action)
        downloads?.activate(itemIDs)
        progressParser = BrewProgressParser()
        defer { flushProgressParser() }

        await runTrackedCommand(status: action.title) { [self] in
            do {
                let result = try await self.runAnsweringPasswords(action)
                self.statusMessage = result.succeeded
                    ? "Finished \(action.commandDisplay)"
                    : "Failed \(action.commandDisplay)"
                if result.succeeded {
                    self.downloads?.settleActiveAction(succeeded: true, message: nil)
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    let inventory = try await self.service.refreshInventory(onOutput: self.makeLogSink())
                    self.packages = inventory.packages
                    self.dependencyGraph = inventory.graph
                } else {
                    self.downloads?.settleActiveAction(
                        succeeded: false,
                        message: PackageStore.failureMessage(from: result)
                    )
                }
            } catch {
                self.downloads?.settleActiveAction(succeeded: false, message: error.localizedDescription)
                throw error
            }
        }
    }

    /// A successful run lingers briefly so the last checkmark is visible; a
    /// failure stays until the user dismisses it.
    private func finishSession() {
        guard let session = downloads, !session.isRunning, !session.hasFailure else { return }
        let revision = sessionRevision
        sessionClearTask?.cancel()

        if downloadLingerNanoseconds == 0 {
            clearDownloadSession()
            return
        }

        sessionClearTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: self?.downloadLingerNanoseconds ?? 0)
            guard !Task.isCancelled, let self, self.sessionRevision == revision else { return }
            self.clearDownloadSession()
        }
    }

    private func flushProgressParser() {
        for event in progressParser.flush() {
            downloads?.apply(event)
        }
        progressParser = BrewProgressParser()
    }

    private static func failureMessage(from result: CommandResult) -> String {
        let lastLine = result.stderr
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .last { !$0.isEmpty }
        if let lastLine { return lastLine }
        return "brew exited with code \(result.exitCode)"
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

        // An action queued while a plain refresh ran would otherwise wait for
        // the next click. Inside the drain loop this is a no-op.
        if !isDraining, !queuedActions.isEmpty {
            await drainQueuedActions()
        }
    }

    private func runAnsweringPasswords(_ action: BrewAction) async throws -> CommandResult {
        // Once brew exits, no prompt from it is left waiting on an answer.
        isAnsweringPasswords = true
        defer { endPasswordRequests() }
        let result = try await service.runAction(
            action,
            onOutput: makeActionSink(),
            onPasswordRequest: makePasswordHandler(for: action)
        )
        savePasswordForTouchID(commandSucceeded: result.succeeded)
        return result
    }

    private func makePasswordHandler(for action: BrewAction) -> SudoPasswordHandler {
        { [weak self] prompt in
            guard let self else { return nil }
            return await self.requestPassword(prompt, for: action)
        }
    }

    private func requestPassword(_ prompt: SudoPasswordPrompt, for action: BrewAction) async -> String? {
        // sudo asks one question at a time, and only while brew runs;
        // anything asking meanwhile or afterwards is refused.
        guard isAnsweringPasswords, !isAskingForPassword, passwordContinuation == nil else { return nil }
        isAskingForPassword = true
        let epoch = passwordEpoch
        defer {
            // An action that ended meanwhile has already reset this.
            if epoch == passwordEpoch {
                isAskingForPassword = false
            }
        }

        let isRetry = prompt.sudoProcessID != nil && prompt.sudoProcessID == lastAnswer?.sudoProcessID
        var notice: PasswordRequest.Notice?
        hasSavedPassword = passwordVault.hasSavedPassword

        if isRetry {
            // sudo is asking again, so the last password was wrong.
            passwordToSave = nil
            if lastAnswer?.fromTouchID == true {
                wantsTouchID = true
                forgetSavedPassword(because: "sudo turned down your saved password, so Brewery forgot it\n")
                notice = .savedPasswordRejected
            } else {
                notice = .wrongPassword
            }
        } else if let earlier = lastAnswer {
            // Another sudo later in the same command, as when sudo's grace
            // period runs out during a long upgrade: reuse what worked.
            lastAnswer = PasswordAnswer(sudoProcessID: prompt.sudoProcessID, password: earlier.password, fromTouchID: earlier.fromTouchID)
            appendLog(.status, "Reusing the password given earlier in this command\n")
            return earlier.password
        } else if hasSavedPassword {
            let unlocked = await passwordVault.unlock(reason: "unlock your saved password for “\(action.title)”")
            guard epoch == passwordEpoch else { return nil }
            switch unlocked {
            case .password(let password):
                lastAnswer = PasswordAnswer(sudoProcessID: prompt.sudoProcessID, password: password, fromTouchID: true)
                appendLog(.status, "Unlocked your saved password with Touch ID\n")
                return password
            case .declined:
                break
            case .invalidated(let reason):
                wantsTouchID = true
                forgetSavedPassword(because: "Touch ID could not unlock your saved password (\(reason)), so Brewery forgot it\n")
                notice = .savedPasswordUnreadable
            }
        }

        appendLog(.status, "Waiting for your administrator password\n")
        let request = PasswordRequest(
            actionTitle: action.title,
            notice: notice,
            offersTouchID: passwordVault.isAvailable,
            usesTouchID: wantsTouchID ?? hasSavedPassword,
            sudoProcessID: prompt.sudoProcessID,
            isRetry: isRetry
        )
        return await withCheckedContinuation { continuation in
            passwordContinuation = continuation
            passwordRequest = request
        }
    }

    /// A password that only a later try got through is kept only if the
    /// command succeeded: sudo may have given up on that try instead.
    private func savePasswordForTouchID(commandSucceeded: Bool) {
        guard let pending = passwordToSave, commandSucceeded || pending.isFirstTry else { return }
        passwordToSave = nil
        do {
            try passwordVault.save(pending.password)
            hasSavedPassword = true
            appendLog(.status, "Saved your password for Touch ID\n")
        } catch {
            appendLog(.stderr, "Brewery could not save your password for Touch ID. \(error.localizedDescription)\n")
        }
    }

    private func forgetSavedPassword(because message: String) {
        guard hasSavedPassword else { return }
        passwordVault.forget()
        hasSavedPassword = false
        appendLog(.status, message)
    }

    private func resolvePasswordRequest(with password: String?) {
        let continuation = passwordContinuation
        passwordContinuation = nil
        passwordRequest = nil
        continuation?.resume(returning: password)
    }

    private func endPasswordRequests() {
        passwordEpoch += 1
        isAnsweringPasswords = false
        isAskingForPassword = false
        resolvePasswordRequest(with: nil)
        lastAnswer = nil
        wantsTouchID = nil
        passwordToSave = nil
    }

    private func makeLogSink() -> @Sendable (CommandLogEntry.Stream, String) -> Void {
        { [weak self] stream, text in
            Task { @MainActor in
                self?.appendLog(stream, text)
            }
        }
    }

    /// The sink used while an action runs: the same log entry, then the
    /// parser, both on the main actor so the two stay in step.
    private func makeActionSink() -> @Sendable (CommandLogEntry.Stream, String) -> Void {
        { [weak self] stream, text in
            Task { @MainActor in
                self?.ingest(stream, text)
            }
        }
    }

    private func ingest(_ stream: CommandLogEntry.Stream, _ text: String) {
        appendLog(stream, text)
        // The status line is Brewery's own "Running brew …", not output.
        guard stream != .status else { return }
        for event in progressParser.consume(text) {
            downloads?.apply(event)
        }
    }

    private func appendLog(_ stream: CommandLogEntry.Stream, _ text: String) {
        logEntries.append(CommandLogEntry(date: Date(), stream: stream, text: text))
    }
}
