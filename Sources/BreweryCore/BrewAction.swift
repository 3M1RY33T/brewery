import Foundation

public enum PackageKind: String, Codable, CaseIterable, Identifiable {
    case formula
    case cask

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .formula: return "Formula"
        case .cask: return "Cask"
        }
    }
}

/// One package a `BrewAction` names, for tracking it while the command runs.
public struct BrewTarget: Identifiable, Equatable {
    public let name: String
    public let kind: PackageKind

    public init(name: String, kind: PackageKind) {
        self.name = name
        self.kind = kind
    }

    public var id: String { PackageNodeID(kind: kind, name: name).id }
}

public enum BrewAction: Identifiable, Equatable {
    case update
    case upgrade(name: String, kind: PackageKind)
    /// Every named package in one `brew upgrade`, so the confirmation shows
    /// precisely which packages are about to change.
    case upgradeAll(names: [String], kind: PackageKind)
    case install(name: String, kind: PackageKind)
    case uninstall(name: String, kind: PackageKind)
    case cleanup

    public var id: String { commandDisplay }

    public var title: String {
        switch self {
        case .update: return "Update Homebrew"
        case .upgrade(let name, _): return "Upgrade \(name)"
        case .upgradeAll(let names, let kind):
            let noun = kind == .cask ? (names.count == 1 ? "Cask" : "Casks") : (names.count == 1 ? "Formula" : "Formulae")
            return "Upgrade \(names.count) \(noun)"
        case .install(let name, _): return "Install \(name)"
        case .uninstall(let name, _): return "Uninstall \(name)"
        case .cleanup: return "Clean Up Homebrew"
        }
    }

    public var isMutating: Bool { true }

    /// The packages this action moves. `update` and `cleanup` touch the whole
    /// installation rather than named packages, so they carry none.
    public var targets: [BrewTarget] {
        switch self {
        case .update, .cleanup:
            return []
        case .upgrade(let name, let kind), .install(let name, let kind), .uninstall(let name, let kind):
            return [BrewTarget(name: name, kind: kind)]
        case .upgradeAll(let names, let kind):
            return names.map { BrewTarget(name: $0, kind: kind) }
        }
    }

    public var arguments: [String] {
        switch self {
        case .update:
            return ["update"]
        case .upgrade(let name, let kind):
            return kind == .cask ? ["upgrade", "--cask", name] : ["upgrade", name]
        case .upgradeAll(let names, let kind):
            return (kind == .cask ? ["upgrade", "--cask"] : ["upgrade"]) + names
        case .install(let name, let kind):
            return kind == .cask ? ["install", "--cask", name] : ["install", name]
        case .uninstall(let name, let kind):
            return kind == .cask ? ["uninstall", "--cask", name] : ["uninstall", name]
        case .cleanup:
            return ["cleanup"]
        }
    }

    public var commandDisplay: String {
        (["brew"] + arguments).joined(separator: " ")
    }
}
