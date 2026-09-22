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
    /// The `.app` bundle this cask installs, when it declares one. Nil for
    /// formulae and for casks that ship only fonts, pkgs or binaries.
    public let appBundleName: String?
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
        appBundleName: String? = nil,
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
        self.appBundleName = appBundleName
        self.pinned = pinned
        self.outdated = outdated
        self.nodeID = PackageNodeID(kind: kind, name: name)
        self.id = nodeID.id
    }
}

extension Array where Element == BrewPackage {
    /// Packages with an upgrade waiting, ahead of the rest. Order within
    /// each group is preserved, so an alphabetical list stays alphabetical
    /// on both sides of the divide.
    public func outdatedFirst() -> [BrewPackage] {
        filter(\.outdated) + filter { !$0.outdated }
    }
}

public enum PackageFilter: String, CaseIterable, Identifiable {
    case browse
    case library
    case diagnostics

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .browse: return "Browse"
        case .library: return "Library"
        case .diagnostics: return "Diagnostics"
        }
    }
}
