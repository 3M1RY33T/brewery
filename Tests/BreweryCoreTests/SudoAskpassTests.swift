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
        let store = PackageStore(service: service)

        let action = Task { await store.perform(.install(name: "docker", kind: .cask)) }
        let request = try await waitForPasswordRequest(in: store)

        XCTAssertEqual(request.actionTitle, "Install docker")
        XCTAssertFalse(request.isRetry)
        XCTAssertTrue(store.isRunningCommand)

        store.submitPassword("hunter2", for: request.id)
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
        let store = PackageStore(service: service)

        let action = Task { await store.perform(.install(name: "docker", kind: .cask)) }
        let first = try await waitForPasswordRequest(in: store)
        XCTAssertFalse(first.isRetry)
        store.submitPassword("wrong", for: first.id)

        let retry = try await waitForPasswordRequest(in: store, after: first)
        XCTAssertTrue(retry.isRetry)
        // An answer to a prompt that has gone does not land on this one.
        store.submitPassword("stale", for: first.id)
        store.cancelPasswordRequest(first.id)
        XCTAssertEqual(store.passwordRequest, retry)
        store.submitPassword("right", for: retry.id)

        let otherSudo = try await waitForPasswordRequest(in: store, after: retry)
        XCTAssertFalse(otherSudo.isRetry, "a different sudo process is a fresh prompt")
        store.submitPassword("right", for: otherSudo.id)
        await action.value

        XCTAssertEqual(service.passwordAnswers, ["wrong", "right", "right"])
    }

    @MainActor
    func testCancellingThePasswordFailsTheCommand() async throws {
        let service = MockBrewService()
        service.passwordPrompts = [SudoPasswordPrompt(message: "Password:", sudoProcessID: 42)]
        let store = PackageStore(service: service)

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

    @MainActor
    private func waitForPasswordRequest(
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
