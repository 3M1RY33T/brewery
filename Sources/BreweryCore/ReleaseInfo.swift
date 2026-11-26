import Foundation

/// One available update, reduced to what Brewery's own surfaces need to show.
/// Sparkle's `SUAppcastItem` is mapped into this pure value in the app target;
/// BreweryCore stays free of any Sparkle dependency so this can be unit-tested.
public struct ReleaseInfo: Equatable {
    /// `CFBundleVersion` — the monotonic build number Sparkle compares on.
    public let versionString: String
    /// `CFBundleShortVersionString` — the human-facing "1.2.0" display version.
    public let displayVersion: String
    /// Release notes, already converted from HTML to plain text.
    public let releaseNotes: String
    /// Where the update can be downloaded, if the appcast item carried one.
    public let downloadURL: URL?
    /// When the release was published, if the appcast item carried one.
    public let publicationDate: Date?

    public init(
        versionString: String,
        displayVersion: String,
        releaseNotes: String,
        downloadURL: URL? = nil,
        publicationDate: Date? = nil
    ) {
        self.versionString = versionString
        self.displayVersion = displayVersion
        self.releaseNotes = releaseNotes
        self.downloadURL = downloadURL
        self.publicationDate = publicationDate
    }
}

/// The state of Brewery's update flow, driven by Sparkle's delegate callbacks.
public enum UpdateState: Equatable {
    case idle
    case checking
    case upToDate
    case updateAvailable(ReleaseInfo)
    case failed(String)
}

/// A version pair, as Sparkle sees it: the build number it actually compares
/// (`CFBundleVersion`) plus the display string users read.
public struct ReleaseVersion: Equatable {
    public var buildNumber: String
    public var displayVersion: String

    public init(buildNumber: String, displayVersion: String) {
        self.buildNumber = buildNumber
        self.displayVersion = displayVersion
    }
}

/// Compares release versions the way Sparkle's default comparator does:
/// `CFBundleVersion` is authoritative when both sides parse as integers, with a
/// semantic-version comparison of the display string as the fallback.
public enum VersionComparator {
    public static func compare(_ candidate: ReleaseVersion, to current: ReleaseVersion) -> ComparisonResult {
        if let c = Int(candidate.buildNumber), let k = Int(current.buildNumber), c != k {
            return c > k ? .orderedDescending : .orderedAscending
        }
        return compareSemver(candidate.displayVersion, current.displayVersion)
    }

    public static func isNewer(_ candidate: ReleaseVersion, than current: ReleaseVersion) -> Bool {
        compare(candidate, to: current) == .orderedDescending
    }

    static func compareSemver(_ a: String, _ b: String) -> ComparisonResult {
        let aParts = semverComponents(a)
        let bParts = semverComponents(b)
        for (x, y) in zip(aParts, bParts) {
            if x != y { return x > y ? .orderedDescending : .orderedAscending }
        }
        if aParts.count != bParts.count {
            return aParts.count > bParts.count ? .orderedDescending : .orderedAscending
        }
        return .orderedSame
    }

    static func semverComponents(_ string: String) -> [Int] {
        string.split(separator: ".", omittingEmptySubsequences: false).map { part in
            let numeric = String(part).prefix { $0.isNumber }
            return Int(numeric) ?? 0
        }
    }
}

/// Converts Sparkle's HTML release notes to plain text: block-level tags become
/// line breaks, remaining tags are stripped, and the common entities are
/// decoded. Deterministic and dependency-free so it can be unit-tested.
public func releaseNotesPlainText(fromHTML html: String) -> String {
    var text = html

    // Block-level boundaries become line breaks so the notes keep their shape.
    text = text.replacingOccurrences(
        of: #"<(?:br|/p|/li|/ul|/ol|/div|/h[1-6])\s*/?>"#,
        with: "\n",
        options: [.regularExpression, .caseInsensitive]
    )

    // Strip every remaining tag.
    text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

    // Decode the entities release notes actually use.
    text = text
        .replacingOccurrences(of: "&amp;", with: "&")
        .replacingOccurrences(of: "&lt;", with: "<")
        .replacingOccurrences(of: "&gt;", with: ">")
        .replacingOccurrences(of: "&quot;", with: "\"")
        .replacingOccurrences(of: "&#39;", with: "'")
        .replacingOccurrences(of: "&nbsp;", with: " ")

    // Trim per-line whitespace, then collapse runs of blank lines.
    let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        .map { $0.trimmingCharacters(in: .whitespaces) }
    var result = lines.joined(separator: "\n")
    result = result.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)

    return result.trimmingCharacters(in: .whitespacesAndNewlines)
}
