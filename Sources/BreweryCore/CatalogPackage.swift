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

public enum CatalogKindFilter: String, CaseIterable, Identifiable {
    case all
    case casks
    case formulae

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .all: return "All"
        case .casks: return "Casks"
        case .formulae: return "Formulae"
        }
    }
}

public enum CatalogCategory: String, CaseIterable, Identifiable {
    case featured
    case guiApps
    case developerTools
    case media
    case productivity
    case cliTools
    case libraries
    case utilities

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .featured: return "Featured"
        case .guiApps: return "GUI Apps"
        case .developerTools: return "Developer Tools"
        case .media: return "Media"
        case .productivity: return "Productivity"
        case .cliTools: return "CLI Tools"
        case .libraries: return "Libraries"
        case .utilities: return "Utilities"
        }
    }

    public static func available(for filter: CatalogKindFilter) -> [CatalogCategory] {
        switch filter {
        case .all:
            return allCases
        case .casks:
            return [.featured, .guiApps, .developerTools, .media, .productivity, .utilities]
        case .formulae:
            return [.featured, .developerTools, .media, .productivity, .cliTools, .libraries, .utilities]
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

    public func categoryScore(for category: CatalogCategory) -> Int {
        let text = searchIndex
        switch category {
        case .featured:
            return 1
        case .guiApps:
            return kind == .cask ? 3 : 0
        case .developerTools:
            return score(text, ["developer", "development", "code", "compiler", "debug", "sdk", "git", "api", "database"])
        case .media:
            return score(text, ["media", "video", "audio", "music", "photo", "image", "player", "stream"])
        case .productivity:
            return score(text, ["productivity", "note", "calendar", "task", "office", "pdf", "document", "writing"])
        case .cliTools:
            return kind == .formula ? score(text, ["cli", "command", "terminal", "shell", "tool"]) + 1 : 0
        case .libraries:
            return kind == .formula ? score(text, ["library", "libraries", "framework", "runtime", "bindings"]) : 0
        case .utilities:
            return isUncategorizedUtility ? 1 : 0
        }
    }

    private var isUncategorizedUtility: Bool {
        let categories = CatalogCategory.available(for: kind == .cask ? .casks : .formulae)
            .filter { $0 != .featured && $0 != .utilities }
        return categories.allSatisfy { categoryScore(forNonFallbackCategory: $0) == 0 }
    }

    private func categoryScore(forNonFallbackCategory category: CatalogCategory) -> Int {
        let text = searchIndex
        switch category {
        case .featured:
            return 1
        case .guiApps:
            return kind == .cask ? 3 : 0
        case .developerTools:
            return score(text, ["developer", "development", "code", "compiler", "debug", "sdk", "git", "api", "database"])
        case .media:
            return score(text, ["media", "video", "audio", "music", "photo", "image", "player", "stream"])
        case .productivity:
            return score(text, ["productivity", "note", "calendar", "task", "office", "pdf", "document", "writing"])
        case .cliTools:
            return kind == .formula ? score(text, ["cli", "command", "terminal", "shell", "tool"]) + 1 : 0
        case .libraries:
            return kind == .formula ? score(text, ["library", "libraries", "framework", "runtime", "bindings"]) : 0
        case .utilities:
            return 0
        }
    }

    private func score(_ text: String, _ keywords: [String]) -> Int {
        keywords.reduce(0) { partial, keyword in
            partial + (text.contains(keyword) ? 1 : 0)
        }
    }
}

public struct CatalogSnapshot: Codable, Equatable {
    public let fetchedAt: Date
    public let packages: [CatalogPackage]
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
            dependencies: try container.decodeIfPresent([String].self, forKey: .dependencies) ?? []
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
    }
}
