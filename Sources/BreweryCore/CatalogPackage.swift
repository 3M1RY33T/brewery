import Combine
import Foundation

public enum CatalogInstallStatus: Equatable {
    case notInstalled
    case installed(outdated: Bool)

    public var title: String {
        switch self {
        case .notInstalled:
            return "Install"
        case .installed(let outdated):
            return outdated ? "Upgrade" : "Installed"
        }
    }
}

public struct CatalogPackage: Identifiable, Equatable {
    public let id: String
    public let nodeID: PackageNodeID
    public let name: String
    public let displayName: String
    public let kind: PackageKind
    public let description: String?
    public let homepage: URL?
    public let version: String?
    public let tap: String?
    public let dependencies: [String]
    /// The `.app` bundle this cask installs, when it declares one. Nil for
    /// formulae and for casks that ship only fonts, pkgs or binaries.
    public let appBundleName: String?
    /// Installs over the last 365 days, from Homebrew's own analytics. Zero
    /// when analytics could not be fetched, which degrades ordering to
    /// alphabetical rather than breaking the shelves.
    public let popularity: Int
    public let searchIndex: String
    public var installStatus: CatalogInstallStatus

    public init(
        name: String,
        displayName: String? = nil,
        kind: PackageKind,
        description: String? = nil,
        homepage: URL? = nil,
        version: String? = nil,
        tap: String? = nil,
        dependencies: [String] = [],
        appBundleName: String? = nil,
        popularity: Int = 0,
        installStatus: CatalogInstallStatus = .notInstalled
    ) {
        self.name = name
        self.displayName = displayName ?? name
        self.kind = kind
        self.description = description
        self.homepage = homepage
        self.version = version
        self.tap = tap
        self.dependencies = dependencies
        self.appBundleName = appBundleName
        self.popularity = popularity
        self.installStatus = installStatus
        self.nodeID = PackageNodeID(kind: kind, name: name)
        self.id = nodeID.id
        self.searchIndex = [
            name,
            displayName ?? name,
            kind.title,
            description,
            tap
        ]
        .compactMap { $0 }
        .joined(separator: " ")
        .lowercased()
    }

    /// A stable colour for this package, derived from its name so the same
    /// package is always tinted the same way across launches.
    public var tintHue: Double {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in name.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        return Double(hash % 360) / 360
    }

    /// A copy carrying a different install status, used when the installed
    /// set changes without the catalog itself being refetched.
    func withInstallStatus(_ status: CatalogInstallStatus) -> CatalogPackage {
        var copy = self
        copy.installStatus = status
        return copy
    }
}

/// One browse shelf: a category, the casks on it, and the formulae on it.
///
/// Both lists are already trimmed to what the shelf displays; `caskTotal` and
/// `formulaTotal` report how many the category holds in full.
public struct CatalogSection: Identifiable, Equatable {
    public let category: CatalogCategory
    public let casks: [CatalogPackage]
    public let formulae: [CatalogPackage]
    public let caskTotal: Int
    public let formulaTotal: Int

    public var id: String { category.rawValue }
    public var isEmpty: Bool { casks.isEmpty && formulae.isEmpty }

    public init(
        category: CatalogCategory,
        casks: [CatalogPackage],
        formulae: [CatalogPackage],
        caskTotal: Int? = nil,
        formulaTotal: Int? = nil
    ) {
        self.category = category
        self.casks = casks
        self.formulae = formulae
        self.caskTotal = caskTotal ?? casks.count
        self.formulaTotal = formulaTotal ?? formulae.count
    }
}

/// Search output, kept split so each kind keeps its own presentation.
public struct CatalogSearchResults: Equatable {
    public let casks: [CatalogPackage]
    public let formulae: [CatalogPackage]

    public var isEmpty: Bool { casks.isEmpty && formulae.isEmpty }

    public init(casks: [CatalogPackage], formulae: [CatalogPackage]) {
        self.casks = casks
        self.formulae = formulae
    }
}

public struct CatalogSnapshot: Codable, Equatable {
    /// Bumped whenever a field is added that the shelves depend on. A cache
    /// written by an older build decodes with a lower version and is refetched
    /// rather than silently producing shelves missing that data.
    public static let currentVersion = 2

    public let version: Int
    public let fetchedAt: Date
    public let packages: [CatalogPackage]

    public init(fetchedAt: Date, packages: [CatalogPackage], version: Int = CatalogSnapshot.currentVersion) {
        self.version = version
        self.fetchedAt = fetchedAt
        self.packages = packages
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        fetchedAt = try container.decode(Date.self, forKey: .fetchedAt)
        packages = try container.decode([CatalogPackage].self, forKey: .packages)
    }

    public var isCurrent: Bool { version == CatalogSnapshot.currentVersion }
}

extension CatalogPackage: Codable {
    private enum CodingKeys: String, CodingKey {
        case name
        case displayName
        case kind
        case description
        case homepage
        case version
        case tap
        case dependencies
        case appBundleName
        case popularity
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let homepageString = try container.decodeIfPresent(String.self, forKey: .homepage)
        self.init(
            name: try container.decode(String.self, forKey: .name),
            displayName: try container.decodeIfPresent(String.self, forKey: .displayName),
            kind: try container.decode(PackageKind.self, forKey: .kind),
            description: try container.decodeIfPresent(String.self, forKey: .description),
            homepage: homepageString.flatMap(URL.init(string:)),
            version: try container.decodeIfPresent(String.self, forKey: .version),
            tap: try container.decodeIfPresent(String.self, forKey: .tap),
            dependencies: try container.decodeIfPresent([String].self, forKey: .dependencies) ?? [],
            appBundleName: try container.decodeIfPresent(String.self, forKey: .appBundleName),
            popularity: try container.decodeIfPresent(Int.self, forKey: .popularity) ?? 0
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(kind, forKey: .kind)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(homepage?.absoluteString, forKey: .homepage)
        try container.encodeIfPresent(version, forKey: .version)
        try container.encodeIfPresent(tap, forKey: .tap)
        try container.encode(dependencies, forKey: .dependencies)
        try container.encodeIfPresent(appBundleName, forKey: .appBundleName)
        try container.encode(popularity, forKey: .popularity)
    }
}
