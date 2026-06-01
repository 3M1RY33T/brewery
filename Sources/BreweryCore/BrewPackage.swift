import Foundation

public struct BrewPackage: Identifiable, Equatable {
    public let id: String
    public let nodeID: PackageNodeID
    public let name: String
    public let displayName: String
    public let kind: PackageKind
    public let tap: String?
    public let description: String?
    public let homepage: URL?
    public let installedVersion: String?
    public let currentVersion: String?
    public let dependencies: [String]
    public let caveats: String?
    public let installedPaths: [String]
    public var pinned: Bool
    public var outdated: Bool

    public init(
        name: String,
        displayName: String? = nil,
        kind: PackageKind,
        tap: String? = nil,
        description: String? = nil,
        homepage: URL? = nil,
        installedVersion: String? = nil,
        currentVersion: String? = nil,
        dependencies: [String] = [],
        caveats: String? = nil,
        installedPaths: [String] = [],
        pinned: Bool = false,
        outdated: Bool = false
    ) {
        self.name = name
        self.displayName = displayName ?? name
        self.kind = kind
        self.tap = tap
        self.description = description
        self.homepage = homepage
        self.installedVersion = installedVersion
        self.currentVersion = currentVersion
        self.dependencies = dependencies
        self.caveats = caveats
        self.installedPaths = installedPaths
        self.pinned = pinned
        self.outdated = outdated
        self.nodeID = PackageNodeID(kind: kind, name: name)
        self.id = nodeID.id
    }
}

public enum PackageFilter: String, CaseIterable, Identifiable {
    case all
    case formulae
    case casks
    case outdated
    case pinned
    case diagnostics

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .all: return "All"
        case .formulae: return "Formulae"
        case .casks: return "Casks"
        case .outdated: return "Outdated"
        case .pinned: return "Pinned"
        case .diagnostics: return "Diagnostics"
        }
    }
}
