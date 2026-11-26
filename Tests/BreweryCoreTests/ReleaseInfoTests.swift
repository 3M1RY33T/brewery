import XCTest
@testable import BreweryCore

final class ReleaseInfoTests: XCTestCase {
    // MARK: - VersionComparator

    func testHigherBuildNumberIsNewer() {
        let current = ReleaseVersion(buildNumber: "4", displayVersion: "1.1.1")
        let candidate = ReleaseVersion(buildNumber: "5", displayVersion: "1.2.0")
        XCTAssertTrue(VersionComparator.isNewer(candidate, than: current))
        XCTAssertFalse(VersionComparator.isNewer(current, than: candidate))
    }

    func testEqualBuildNumberIsNotNewer() {
        let current = ReleaseVersion(buildNumber: "4", displayVersion: "1.1.1")
        let candidate = ReleaseVersion(buildNumber: "4", displayVersion: "1.1.1")
        XCTAssertFalse(VersionComparator.isNewer(candidate, than: current))
        XCTAssertEqual(VersionComparator.compare(candidate, to: current), .orderedSame)
    }

    func testLowerBuildNumberIsNotNewer() {
        let current = ReleaseVersion(buildNumber: "5", displayVersion: "1.2.0")
        let candidate = ReleaseVersion(buildNumber: "4", displayVersion: "1.1.1")
        XCTAssertFalse(VersionComparator.isNewer(candidate, than: current))
    }

    func testFallsBackToSemverWhenBuildNumbersAreEqual() {
        // Same build number forces the semver path; the higher display wins.
        let current = ReleaseVersion(buildNumber: "4", displayVersion: "1.1.1")
        let candidate = ReleaseVersion(buildNumber: "4", displayVersion: "1.1.2")
        XCTAssertTrue(VersionComparator.isNewer(candidate, than: current))
    }

    func testFallsBackToSemverWhenBuildNumbersAreUnparseable() {
        let current = ReleaseVersion(buildNumber: "n/a", displayVersion: "2.0.0")
        let candidate = ReleaseVersion(buildNumber: "n/a", displayVersion: "2.1.0")
        XCTAssertTrue(VersionComparator.isNewer(candidate, than: current))
    }

    func testSemverMultiSegmentComparison() {
        XCTAssertTrue(VersionComparator.compareSemver("1.10.0", "1.9.0") == .orderedDescending)
        XCTAssertTrue(VersionComparator.compareSemver("1.2.0", "1.2.0") == .orderedSame)
        XCTAssertTrue(VersionComparator.compareSemver("1.2.0", "1.2.1") == .orderedAscending)
        // Longer wins when the shared prefix is equal.
        XCTAssertTrue(VersionComparator.compareSemver("1.2.0", "1.2") == .orderedDescending)
    }

    // MARK: - releaseNotesPlainText

    func testStripsTagsAndPreservesLineBreaks() {
        let html = "<p>First line</p><p>Second line</p>"
        XCTAssertEqual(releaseNotesPlainText(fromHTML: html), "First line\nSecond line")
    }

    func testConvertsBreakTagsToNewlines() {
        let html = "Fixed a crash<br>and another<br/>bug"
        XCTAssertEqual(releaseNotesPlainText(fromHTML: html), "Fixed a crash\nand another\nbug")
    }

    func testDecodesCommonEntities() {
        let html = "Cats &amp; dogs &lt;3 &quot;quotes&quot;"
        XCTAssertEqual(releaseNotesPlainText(fromHTML: html), "Cats & dogs <3 \"quotes\"")
    }

    func testCollapsesBlankLinesAndTrimsWhitespace() {
        let html = "<ul><li>one</li><li>two</li></ul>\n\n\n<p>trailing</p>"
        XCTAssertEqual(releaseNotesPlainText(fromHTML: html), "one\ntwo\n\ntrailing")
    }

    func testEmptyHTMLIsEmptyString() {
        XCTAssertEqual(releaseNotesPlainText(fromHTML: ""), "")
        XCTAssertEqual(releaseNotesPlainText(fromHTML: "<p></p>"), "")
    }
}
