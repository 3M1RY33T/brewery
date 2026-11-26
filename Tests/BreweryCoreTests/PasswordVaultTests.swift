import CryptoKit
import XCTest
@testable import BreweryCore

final class PasswordVaultTests: XCTestCase {
    func testSealedPasswordOpensOnlyWithItsRecipientKey() throws {
        // A software key stands in for the Secure Enclave one.
        let recipient = P256.KeyAgreement.PrivateKey()
        let sealed = try SealedPassword.seal("correct horse", to: recipient.publicKey, enclaveKey: Data("blob".utf8))

        XCTAssertEqual(try sealed.open { try recipient.sharedSecretFromKeyAgreement(with: $0) }, "correct horse")
        XCTAssertEqual(sealed.enclaveKey, Data("blob".utf8))

        let stranger = P256.KeyAgreement.PrivateKey()
        XCTAssertThrowsError(try sealed.open { try stranger.sharedSecretFromKeyAgreement(with: $0) })

        var tampered = sealed.box
        tampered[tampered.count - 1] ^= 0xFF
        let damaged = SealedPassword(enclaveKey: sealed.enclaveKey, ephemeralPublicKey: sealed.ephemeralPublicKey, box: tampered)
        XCTAssertThrowsError(try damaged.open { try recipient.sharedSecretFromKeyAgreement(with: $0) })
    }

    func testSecureEnclaveVaultKeepsOnlyCiphertextInAPrivateFile() throws {
        try XCTSkipUnless(SecureEnclave.isAvailable, "needs a Secure Enclave")
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("vault-\(UUID().uuidString).json")
        addTeardownBlock { try? FileManager.default.removeItem(at: file) }
        let vault = SecureEnclavePasswordVault(fileURL: file)
        XCTAssertFalse(vault.hasSavedPassword)

        // Creating the key and sealing never asks for Touch ID.
        try vault.save("hunter2-secret")

        XCTAssertTrue(vault.hasSavedPassword)
        XCTAssertEqual(try FileManager.default.attributesOfItem(atPath: file.path)[.posixPermissions] as? Int, 0o600)
        let contents = try Data(contentsOf: file)
        XCTAssertNoThrow(try JSONDecoder().decode(SealedPassword.self, from: contents))
        XCTAssertNil(String(decoding: contents, as: UTF8.self).range(of: "hunter2"))

        vault.forget()
        XCTAssertFalse(vault.hasSavedPassword)
    }

    func testMissingOrDamagedVaultIsInvalidWithoutAskingForTouchID() async throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("vault-\(UUID().uuidString).json")
        addTeardownBlock { try? FileManager.default.removeItem(at: file) }
        let vault = SecureEnclavePasswordVault(fileURL: file)

        let missing = await vault.unlock(reason: "test")
        XCTAssertEqual(missing, .invalidated("the saved password file could not be read"))

        try Data("not a vault".utf8).write(to: file)
        let damaged = await vault.unlock(reason: "test")
        XCTAssertEqual(damaged, .invalidated("the saved password file could not be read"))
    }

    @MainActor
    func testTouchIDAnswersSudoWithoutTheSheet() async throws {
        let vault = MockPasswordVault(saved: "hunter2")
        let service = MockBrewService()
        service.passwordPrompts = [SudoPasswordPrompt(message: "Password:", sudoProcessID: 42)]
        let store = PackageStore(service: service, passwordVault: vault)

        await store.perform(.install(name: "docker", kind: .cask))

        XCTAssertEqual(service.passwordAnswers, ["hunter2"])
        XCTAssertEqual(vault.unlockReasons, ["unlock your saved password for “Install docker”"])
        XCTAssertTrue(store.logEntries.contains { $0.text == "Unlocked your saved password with Touch ID\n" })
        XCTAssertFalse(store.logEntries.contains { $0.text.contains("hunter2") }, "the password never reaches the log")
        XCTAssertEqual(vault.saveCount, 0)
    }

    @MainActor
    func testDecliningTouchIDFallsBackToTheSheetAndKeepsThePassword() async throws {
        let vault = MockPasswordVault(saved: "old", unlockResult: .declined)
        let service = MockBrewService()
        service.passwordPrompts = [SudoPasswordPrompt(message: "Password:", sudoProcessID: 42)]
        let store = PackageStore(service: service, passwordVault: vault)

        let action = Task { await store.perform(.install(name: "docker", kind: .cask)) }
        let request = try await waitForPasswordRequest(in: store)

        XCTAssertNil(request.notice)
        XCTAssertTrue(request.offersTouchID)
        XCTAssertTrue(request.usesTouchID, "the checkbox starts on while a password is saved")
        XCTAssertEqual(vault.saved, "old")

        store.submitPassword("typed", rememberWithTouchID: true, for: request.id)
        await action.value

        XCTAssertEqual(service.passwordAnswers, ["typed"])
        XCTAssertEqual(vault.saved, "typed", "the password that just worked replaces the saved one")
    }

    @MainActor
    func testSavedPasswordSudoTurnsDownIsForgotten() async throws {
        let vault = MockPasswordVault(saved: "stale")
        let service = MockBrewService()
        service.passwordPrompts = [
            SudoPasswordPrompt(message: "Password:", sudoProcessID: 42),
            SudoPasswordPrompt(message: "Password:", sudoProcessID: 42)
        ]
        let store = PackageStore(service: service, passwordVault: vault)

        let action = Task { await store.perform(.install(name: "docker", kind: .cask)) }
        let request = try await waitForPasswordRequest(in: store)

        XCTAssertEqual(request.notice, .savedPasswordRejected)
        XCTAssertTrue(request.usesTouchID, "they had opted in, so the checkbox stays on")
        XCTAssertNil(vault.saved)
        XCTAssertFalse(store.hasSavedPassword)
        XCTAssertEqual(vault.unlockReasons.count, 1, "Touch ID is not offered again for the same sudo")

        store.submitPassword("new", rememberWithTouchID: true, for: request.id)
        await action.value

        XCTAssertEqual(service.passwordAnswers, ["stale", "new"])
        XCTAssertEqual(vault.saved, "new")
        XCTAssertTrue(store.hasSavedPassword)
    }

    @MainActor
    func testPasswordTouchIDCanNoLongerUnlockIsForgotten() async throws {
        let vault = MockPasswordVault(saved: "pw", unlockResult: .invalidated("the Secure Enclave key refused"))
        let service = MockBrewService()
        service.passwordPrompts = [SudoPasswordPrompt(message: "Password:", sudoProcessID: 42)]
        let store = PackageStore(service: service, passwordVault: vault)

        let action = Task { await store.perform(.install(name: "docker", kind: .cask)) }
        let request = try await waitForPasswordRequest(in: store)

        XCTAssertEqual(request.notice, .savedPasswordUnreadable)
        XCTAssertNil(vault.saved)
        XCTAssertTrue(
            store.logEntries.contains { $0.text.contains("(the Secure Enclave key refused)") },
            "the log says why the password was forgotten"
        )

        store.cancelPasswordRequest(request.id)
        await action.value

        XCTAssertEqual(service.passwordAnswers, [nil])
        XCTAssertEqual(vault.saveCount, 0)
    }

    @MainActor
    func testOptingInSavesOnlyThePasswordSudoAccepted() async throws {
        let vault = MockPasswordVault()
        let service = MockBrewService()
        service.passwordPrompts = [
            SudoPasswordPrompt(message: "Password:", sudoProcessID: 42),
            SudoPasswordPrompt(message: "Password:", sudoProcessID: 42)
        ]
        let store = PackageStore(service: service, passwordVault: vault)

        let action = Task { await store.perform(.install(name: "docker", kind: .cask)) }
        let first = try await waitForPasswordRequest(in: store)
        XCTAssertTrue(first.offersTouchID)
        XCTAssertFalse(first.usesTouchID, "Touch ID is opt-in")
        store.submitPassword("wrong", rememberWithTouchID: true, for: first.id)

        let retry = try await waitForPasswordRequest(in: store, after: first)
        XCTAssertEqual(retry.notice, .wrongPassword)
        XCTAssertTrue(retry.usesTouchID, "the checkbox keeps the choice just made")
        XCTAssertNil(vault.saved, "nothing is saved while the command runs")
        store.submitPassword("right", rememberWithTouchID: true, for: retry.id)
        await action.value

        XCTAssertEqual(vault.saved, "right")
        XCTAssertEqual(vault.saveCount, 1)
    }

    @MainActor
    func testNothingIsSavedWhenTheCommandFails() async throws {
        let vault = MockPasswordVault()
        let service = MockBrewService()
        service.passwordPrompts = [
            SudoPasswordPrompt(message: "Password:", sudoProcessID: 42),
            SudoPasswordPrompt(message: "Password:", sudoProcessID: 42)
        ]
        let store = PackageStore(service: service, passwordVault: vault)

        let action = Task { await store.perform(.install(name: "docker", kind: .cask)) }
        let first = try await waitForPasswordRequest(in: store)
        store.submitPassword("wrong", rememberWithTouchID: true, for: first.id)
        let retry = try await waitForPasswordRequest(in: store, after: first)
        store.cancelPasswordRequest(retry.id)
        await action.value

        XCTAssertEqual(store.statusMessage, "Failed brew install --cask docker")
        XCTAssertNil(vault.saved)
        XCTAssertEqual(vault.saveCount, 0)
    }

    @MainActor
    func testPasswordSudoTookFirstTimeIsSavedEvenIfTheCommandFails() async throws {
        let vault = MockPasswordVault()
        let service = MockBrewService()
        service.passwordPrompts = [SudoPasswordPrompt(message: "Password:", sudoProcessID: 42)]
        service.actionExitCode = 1
        let store = PackageStore(service: service, passwordVault: vault)

        let action = Task { await store.perform(.install(name: "docker", kind: .cask)) }
        let request = try await waitForPasswordRequest(in: store)
        store.submitPassword("right", rememberWithTouchID: true, for: request.id)
        await action.value

        // A wrong first try would have drawn a retry; none came.
        XCTAssertEqual(store.statusMessage, "Failed brew install --cask docker")
        XCTAssertEqual(vault.saved, "right")
    }

    @MainActor
    func testLaterTryIsNotSavedWhenTheCommandFails() async throws {
        let vault = MockPasswordVault()
        let service = MockBrewService()
        service.passwordPrompts = [
            SudoPasswordPrompt(message: "Password:", sudoProcessID: 42),
            SudoPasswordPrompt(message: "Password:", sudoProcessID: 42)
        ]
        service.actionExitCode = 1
        let store = PackageStore(service: service, passwordVault: vault)

        let action = Task { await store.perform(.install(name: "docker", kind: .cask)) }
        let first = try await waitForPasswordRequest(in: store)
        store.submitPassword("wrong", rememberWithTouchID: true, for: first.id)
        let retry = try await waitForPasswordRequest(in: store, after: first)
        store.submitPassword("maybe", rememberWithTouchID: true, for: retry.id)
        await action.value

        // sudo may have given up on that try rather than taken it.
        XCTAssertNil(vault.saved)
    }

    @MainActor
    func testTouchIDPromptThatOutlivesItsCommandChangesNothing() async throws {
        let vault = MockPasswordVault(saved: "pw")
        vault.holdsUnlock = true
        let service = AbandoningBrewService(laterPrompts: [SudoPasswordPrompt(message: "Password:", sudoProcessID: 43)]) {
            while !vault.isHoldingUnlock {
                try? await Task.sleep(nanoseconds: 5_000_000)
            }
        }
        let store = PackageStore(service: service, passwordVault: vault)

        // brew dies while the Touch ID prompt is still up.
        await store.perform(.install(name: "docker", kind: .cask))
        XCTAssertTrue(vault.isHoldingUnlock)

        // The next command can still ask, and Touch ID answers it.
        await store.perform(.install(name: "vlc", kind: .cask))
        XCTAssertEqual(service.passwordAnswers, ["pw"])

        // The old prompt finally fails; nothing from it lands.
        vault.finishHeldUnlock(.invalidated("late"))
        try await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(vault.saved, "pw")
        XCTAssertTrue(store.hasSavedPassword)
        XCTAssertNil(store.passwordRequest)
    }

    @MainActor
    func testUncheckingTouchIDForgetsTheSavedPassword() async throws {
        let vault = MockPasswordVault(saved: "pw", unlockResult: .declined)
        let service = MockBrewService()
        service.passwordPrompts = [SudoPasswordPrompt(message: "Password:", sudoProcessID: 42)]
        let store = PackageStore(service: service, passwordVault: vault)

        let action = Task { await store.perform(.install(name: "docker", kind: .cask)) }
        let request = try await waitForPasswordRequest(in: store)
        store.submitPassword("typed", rememberWithTouchID: false, for: request.id)
        await action.value

        XCTAssertNil(vault.saved)
        XCTAssertFalse(store.hasSavedPassword)
        XCTAssertEqual(vault.saveCount, 0)
    }

    @MainActor
    func testWithoutTouchIDTheSavedPasswordIsLeftAlone() async throws {
        // Lid closed: no Touch ID, so the sheet shows no checkbox.
        let vault = MockPasswordVault(isAvailable: false, saved: "pw", unlockResult: .declined)
        let service = MockBrewService()
        service.passwordPrompts = [SudoPasswordPrompt(message: "Password:", sudoProcessID: 42)]
        let store = PackageStore(service: service, passwordVault: vault)

        let action = Task { await store.perform(.install(name: "docker", kind: .cask)) }
        let request = try await waitForPasswordRequest(in: store)
        XCTAssertFalse(request.offersTouchID)
        store.submitPassword("typed", rememberWithTouchID: nil, for: request.id)
        await action.value

        XCTAssertEqual(vault.saved, "pw")
        XCTAssertEqual(vault.saveCount, 0)
    }

    @MainActor
    func testForgetSavedPasswordFromTheMenu() {
        let vault = MockPasswordVault(saved: "pw")
        let store = PackageStore(service: MockBrewService(), passwordVault: vault)
        XCTAssertTrue(store.hasSavedPassword)

        store.forgetSavedPassword()

        XCTAssertFalse(store.hasSavedPassword)
        XCTAssertNil(vault.saved)
    }
}

final class MockPasswordVault: PasswordVaulting {
    var isAvailable: Bool
    var saved: String?
    /// What Touch ID does; nil hands back the saved password.
    var unlockResult: PasswordVaultUnlock?
    private(set) var unlockReasons: [String] = []
    private(set) var saveCount = 0
    /// Makes the next unlock wait for `finishHeldUnlock`, like a Touch ID
    /// prompt left open.
    var holdsUnlock = false
    private var heldUnlock: CheckedContinuation<PasswordVaultUnlock, Never>?

    var isHoldingUnlock: Bool { heldUnlock != nil }

    func finishHeldUnlock(_ result: PasswordVaultUnlock) {
        heldUnlock?.resume(returning: result)
        heldUnlock = nil
    }

    init(isAvailable: Bool = true, saved: String? = nil, unlockResult: PasswordVaultUnlock? = nil) {
        self.isAvailable = isAvailable
        self.saved = saved
        self.unlockResult = unlockResult
    }

    var hasSavedPassword: Bool { saved != nil }

    func save(_ password: String) throws {
        saved = password
        saveCount += 1
    }

    func unlock(reason: String) async -> PasswordVaultUnlock {
        unlockReasons.append(reason)
        if holdsUnlock {
            holdsUnlock = false
            return await withCheckedContinuation { heldUnlock = $0 }
        }
        return unlockResult ?? saved.map(PasswordVaultUnlock.password) ?? .invalidated("no saved password")
    }

    func forget() {
        saved = nil
    }
}

/// Stands in for a brew killed while sudo waits: the first action relays a
/// prompt, waits for `whilePromptIsOpen`, then fails without the answer.
/// Later actions behave like `MockBrewService` with `laterPrompts`.
private final class AbandoningBrewService: BrewServicing {
    private let inner = MockBrewService()
    private let whilePromptIsOpen: () async -> Void
    private var actionCount = 0

    init(laterPrompts: [SudoPasswordPrompt], whilePromptIsOpen: @escaping () async -> Void) {
        inner.passwordPrompts = laterPrompts
        self.whilePromptIsOpen = whilePromptIsOpen
    }

    var detectionReport: BrewDetectionReport { inner.detectionReport }
    var brewPath: URL? { inner.brewPath }
    var passwordAnswers: [String?] { inner.passwordAnswers }

    func refreshInventory(onOutput: @escaping @Sendable (CommandLogEntry.Stream, String) -> Void) async throws -> BrewInventory {
        try await inner.refreshInventory(onOutput: onOutput)
    }

    func refreshPackages(onOutput: @escaping @Sendable (CommandLogEntry.Stream, String) -> Void) async throws -> [BrewPackage] {
        try await inner.refreshPackages(onOutput: onOutput)
    }

    func diagnostics(onOutput: @escaping @Sendable (CommandLogEntry.Stream, String) -> Void) async throws -> BrewDiagnostics {
        try await inner.diagnostics(onOutput: onOutput)
    }

    func runAction(
        _ action: BrewAction,
        onOutput: @escaping @Sendable (CommandLogEntry.Stream, String) -> Void,
        onPasswordRequest: @escaping SudoPasswordHandler
    ) async throws -> CommandResult {
        actionCount += 1
        guard actionCount == 1 else {
            return try await inner.runAction(action, onOutput: onOutput, onPasswordRequest: onPasswordRequest)
        }
        Task { _ = await onPasswordRequest(SudoPasswordPrompt(message: "Password:", sudoProcessID: 42)) }
        await whilePromptIsOpen()
        return CommandResult(
            commandDisplay: action.commandDisplay,
            stdout: "",
            stderr: "Killed\n",
            exitCode: 137,
            startedAt: Date(),
            finishedAt: Date()
        )
    }
}
