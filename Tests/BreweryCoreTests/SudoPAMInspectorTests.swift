import XCTest
@testable import BreweryCore

final class SudoPAMInspectorTests: XCTestCase {
    func testDetectsTouchIDAndSmartcardSufficientAuthLines() {
        let modules = SudoPAMInspector.preemptingModules(in: """
        # sudo: auth account password session
        auth sufficient pam_tid.so
        auth include sudo_local
        auth sufficient pam_smartcard.so
        auth required pam_opendirectory.so
        """)
        XCTAssertEqual(modules, ["pam_tid.so", "pam_smartcard.so"])
    }

    func testIgnoresNonSufficientNonAuthAndCommentedLines() {
        let modules = SudoPAMInspector.preemptingModules(in: """
        auth optional pam_tid.so
        account sufficient pam_tid.so
        # auth sufficient pam_tid.so
        auth required pam_opendirectory.so
        """)
        XCTAssertEqual(modules, [])
    }

    func testIgnoresThePasswordModuleItself() {
        let modules = SudoPAMInspector.preemptingModules(in: """
        auth sufficient pam_opendirectory.so
        auth required pam_opendirectory.so
        """)
        XCTAssertEqual(modules, [])
    }

    func testHandlesTabSeparatedFields() {
        let modules = SudoPAMInspector.preemptingModules(in: "auth\tsufficient\tpam_tid.so\n")
        XCTAssertEqual(modules, ["pam_tid.so"])
    }

    func testInspectAggregatesAcrossFilesAndSkipsMissing() {
        let inspector = SudoPAMInspector(
            paths: ["/etc/pam.d/sudo", "/etc/pam.d/sudo_local"],
            read: { path in
                switch path {
                case "/etc/pam.d/sudo":
                    return "auth sufficient pam_tid.so\n"
                case "/etc/pam.d/sudo_local":
                    return "auth sufficient pam_smartcard.so\n"
                default:
                    throw NSError(domain: "test", code: 2)
                }
            }
        )
        let report = inspector.inspect()
        XCTAssertEqual(report.preemptingModules, ["pam_tid.so", "pam_smartcard.so"])
        XCTAssertEqual(report.sources, ["/etc/pam.d/sudo", "/etc/pam.d/sudo_local"])
        XCTAssertTrue(report.usesTouchID)
        XCTAssertTrue(report.usesSmartcard)
        XCTAssertTrue(report.canPreemptPassword)
        XCTAssertEqual(report.preemptionNotice, report.explanation)
    }

    func testReportWithoutPreemption() {
        let report = SudoPAMReport(preemptingModules: [], sources: [])
        XCTAssertFalse(report.canPreemptPassword)
        XCTAssertFalse(report.usesTouchID)
        XCTAssertFalse(report.usesSmartcard)
        XCTAssertNil(report.preemptionNotice)
        XCTAssertEqual(report.explanation, "Sudo uses password authentication.")
    }

    @MainActor
    func testStoreLogsSudoNoticeWhenTouchIDPreempts() async {
        let report = SudoPAMReport(preemptingModules: ["pam_tid.so"], sources: ["/etc/pam.d/sudo"])
        let store = PackageStore(service: MockBrewService(), sudoAuthentication: report)

        await store.perform(.install(name: "warp", kind: .cask))

        XCTAssertTrue(
            store.logEntries.contains { $0.stream == .status && $0.text == report.explanation + "\n" },
            "a preempting sudo config should be explained in the command log"
        )
    }

    @MainActor
    func testStoreLogsNothingWhenPasswordAuthenticates() async {
        let report = SudoPAMReport(preemptingModules: [], sources: [])
        let store = PackageStore(service: MockBrewService(), sudoAuthentication: report)

        await store.perform(.install(name: "warp", kind: .cask))

        XCTAssertFalse(
            store.logEntries.contains { $0.text == "Sudo uses password authentication.\n" },
            "the ordinary password path needs no warning line"
        )
    }
}
