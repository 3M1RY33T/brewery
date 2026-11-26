import Darwin
import XCTest
@testable import BreweryCore

final class SudoAskpassTests: XCTestCase {
    func testHelperPrintsTheAnsweredPasswordForSudo() async throws {
        let askpass = try SudoAskpass()
        let prompts = PromptRecorder()

        let result = try await askpass.serving({ prompt in
            await prompts.record(prompt)
            return "correct horse 'battery' $staple"
        }) {
            try await runHelper(askpass, prompt: "Password:")
        }

        XCTAssertEqual(result.stdout, "correct horse 'battery' $staple\n")
        // The helper's parent stands in for sudo here.
        let recorded = await prompts.all
        XCTAssertEqual(recorded, [SudoPasswordPrompt(message: "Password:", sudoProcessID: getpid())])
    }

    func testCancelledPromptPrintsNothingSoSudoGivesUp() async throws {
        let askpass = try SudoAskpass()

        let result = try await askpass.serving({ _ in nil }) {
            try await runHelper(askpass, prompt: "Password:")
        }

        XCTAssertEqual(result.stdout, "")
    }

    func testPromptsOutsideAnActionAreRefused() async throws {
        let askpass = try SudoAskpass()

        let result = try await runHelper(askpass, prompt: "Password:")

        XCTAssertEqual(result.stdout, "")
    }

    func testProgramsBreweryDidNotStartAreRefused() async throws {
        // Trust a live process that is not an ancestor of the helper, so the
        // helper stands in for a program Brewery never launched.
        let stranger = Process()
        stranger.executableURL = URL(fileURLWithPath: "/bin/sleep")
        stranger.arguments = ["30"]
        try stranger.run()
        addTeardownBlock { stranger.terminate() }
        let askpass = try SudoAskpass(trustedAncestor: stranger.processIdentifier)
        let prompts = PromptRecorder()

        let result = try await askpass.serving({ prompt in
            await prompts.record(prompt)
            return "hunter2"
        }) {
            try await runHelper(askpass, prompt: "Password:")
        }

        XCTAssertEqual(result.stdout, "")
        let recorded = await prompts.all
        XCTAssertTrue(recorded.isEmpty, "the prompt is never even read")
    }

    func testOrphanedProcessIsRefused() async throws {
        let askpass = try SudoAskpass()
        let prompts = PromptRecorder()
        let output = askpass.directoryURL.appendingPathComponent("orphan-output")
        let done = askpass.directoryURL.appendingPathComponent("orphan-done")
        let socket = askpass.directoryURL.appendingPathComponent("socket").path

        let found = try await askpass.serving({ prompt in
            await prompts.record(prompt)
            return "hunter2"
        }) { () async throws -> Bool in
            // The background subshell outlives its parent, so launchd adopts
            // it before it connects: it no longer descends from this process.
            _ = try await CommandRunner().run(
                executableURL: URL(fileURLWithPath: "/bin/sh"),
                arguments: ["-c", "( sleep 0.3; printf '1\\nPassword:\\n' | /usr/bin/nc -U '\(socket)' > '\(output.path)'; touch '\(done.path)' ) &"]
            )
            for _ in 0..<300 where !FileManager.default.fileExists(atPath: done.path) {
                try await Task.sleep(nanoseconds: 10_000_000)
            }
            return FileManager.default.fileExists(atPath: done.path)
        }

        XCTAssertTrue(found, "the orphan finished")
        XCTAssertEqual(try String(contentsOf: output, encoding: .utf8), "")
        let recorded = await prompts.all
        XCTAssertTrue(recorded.isEmpty)
    }

    func testHelperIsPrivateAndNamedBySudoAskpass() throws {
        let askpass = try SudoAskpass()
        let fileManager = FileManager.default

        XCTAssertEqual(askpass.environment, ["SUDO_ASKPASS": askpass.helperURL.path])
        XCTAssertTrue(fileManager.isExecutableFile(atPath: askpass.helperURL.path))
        XCTAssertEqual(try fileManager.attributesOfItem(atPath: askpass.directoryURL.path)[.posixPermissions] as? Int, 0o700)
        XCTAssertEqual(try fileManager.attributesOfItem(atPath: askpass.helperURL.path)[.posixPermissions] as? Int, 0o700)
    }

    func testHelperDirectoryGoesAwayWithTheHelper() throws {
        var askpass: SudoAskpass? = try SudoAskpass()
        let directory = try XCTUnwrap(askpass?.directoryURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.path))

        askpass = nil

        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path))
    }

    func testDirectoriesLeftByBreweriesThatQuitAreRemoved() throws {
        let fileManager = FileManager.default
        // Short on purpose: the socket path inside has to fit in 104 bytes.
        let parent = fileManager.temporaryDirectory.appendingPathComponent("bw-\(UUID().uuidString.prefix(6))")
        try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
        addTeardownBlock { try? fileManager.removeItem(at: parent) }

        let exited = Process()
        exited.executableURL = URL(fileURLWithPath: "/usr/bin/true")
        try exited.run()
        exited.waitUntilExit()

        let abandoned = parent.appendingPathComponent("\(SudoAskpass.directoryPrefix)\(exited.processIdentifier).abc123")
        let stillRunning = parent.appendingPathComponent("\(SudoAskpass.directoryPrefix)\(getpid()).def456")
        try fileManager.createDirectory(at: abandoned, withIntermediateDirectories: false)
        try fileManager.createDirectory(at: stillRunning, withIntermediateDirectories: false)

        let askpass = try SudoAskpass(parentDirectory: parent)

        XCTAssertFalse(fileManager.fileExists(atPath: abandoned.path))
        XCTAssertTrue(fileManager.fileExists(atPath: stillRunning.path))
        XCTAssertTrue(fileManager.fileExists(atPath: askpass.directoryURL.path))
    }

    func testParsesTheHelperRequest() {
        XCTAssertEqual(
            SudoPasswordPrompt(request: "4242\nPassword:\n"),
            SudoPasswordPrompt(message: "Password:", sudoProcessID: 4242)
        )
        XCTAssertNil(SudoPasswordPrompt(request: "\nPassword:\n")?.sudoProcessID)
        XCTAssertNil(SudoPasswordPrompt(request: ""))
    }

    @MainActor
    func testPasswordPromptWaitsForTheUserThenAnswersSudo() async throws {
        let service = MockBrewService()
        service.passwordPrompts = [SudoPasswordPrompt(message: "Password:", sudoProcessID: 42)]
        let store = PackageStore(service: service, passwordVault: MockPasswordVault())

        let action = Task { await store.perform(.install(name: "docker", kind: .cask)) }
        let request = try await waitForPasswordRequest(in: store)

        XCTAssertEqual(request.actionTitle, "Install docker")
        XCTAssertNil(request.notice)
        XCTAssertTrue(store.isRunningCommand)

        store.submitPassword("hunter2", rememberWithTouchID: nil, for: request.id)
        await action.value

        XCTAssertEqual(service.passwordAnswers, ["hunter2"])
        XCTAssertNil(store.passwordRequest)
        XCTAssertEqual(store.statusMessage, "Finished brew install --cask docker")
    }

    @MainActor
    func testRepeatPromptFromTheSameSudoMeansTheLastPasswordWasWrong() async throws {
        let service = MockBrewService()
        service.passwordPrompts = [
            SudoPasswordPrompt(message: "Password:", sudoProcessID: 42),
            SudoPasswordPrompt(message: "Password:", sudoProcessID: 42),
            SudoPasswordPrompt(message: "Password:", sudoProcessID: 43)
        ]
        let store = PackageStore(service: service, passwordVault: MockPasswordVault())

        let action = Task { await store.perform(.install(name: "docker", kind: .cask)) }
        let first = try await waitForPasswordRequest(in: store)
        XCTAssertNil(first.notice)
        store.submitPassword("wrong", rememberWithTouchID: nil, for: first.id)

        let retry = try await waitForPasswordRequest(in: store, after: first)
        XCTAssertEqual(retry.notice, .wrongPassword)
        // An answer to a prompt that has gone does not land on this one.
        store.submitPassword("stale", rememberWithTouchID: nil, for: first.id)
        store.cancelPasswordRequest(first.id)
        XCTAssertEqual(store.passwordRequest, retry)
        store.submitPassword("right", rememberWithTouchID: nil, for: retry.id)

        await action.value

        // A later sudo in the same command gets the password that worked,
        // without asking again.
        XCTAssertEqual(service.passwordAnswers, ["wrong", "right", "right"])
        XCTAssertTrue(store.logEntries.contains { $0.text == "Reusing the password given earlier in this command\n" })
    }

    @MainActor
    func testCancellingThePasswordFailsTheCommand() async throws {
        let service = MockBrewService()
        service.passwordPrompts = [SudoPasswordPrompt(message: "Password:", sudoProcessID: 42)]
        let store = PackageStore(service: service, passwordVault: MockPasswordVault())

        let action = Task { await store.perform(.install(name: "docker", kind: .cask)) }
        let request = try await waitForPasswordRequest(in: store)
        store.cancelPasswordRequest(request.id)
        await action.value

        XCTAssertEqual(service.passwordAnswers, [nil])
        XCTAssertNil(store.passwordRequest)
        XCTAssertFalse(store.isRunningCommand)
        XCTAssertEqual(store.statusMessage, "Failed brew install --cask docker")
    }

    private func runHelper(_ askpass: SudoAskpass, prompt: String) async throws -> CommandResult {
        try await CommandRunner().run(executableURL: askpass.helperURL, arguments: [prompt])
    }
}

extension XCTestCase {
    /// The sheet's request once one is showing, skipping `previous`.
    @MainActor
    func waitForPasswordRequest(
        in store: PackageStore,
        after previous: PasswordRequest? = nil
    ) async throws -> PasswordRequest {
        for _ in 0..<300 {
            if let request = store.passwordRequest, request.id != previous?.id {
                return request
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        throw NoPasswordRequest()
    }
}

private struct NoPasswordRequest: Error {}

private actor PromptRecorder {
    private(set) var all: [SudoPasswordPrompt] = []

    func record(_ prompt: SudoPasswordPrompt) {
        all.append(prompt)
    }
}
