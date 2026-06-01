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

public enum BrewAction: Identifiable, Equatable {
    case update
    case upgrade(name: String, kind: PackageKind)
    case install(name: String, kind: PackageKind)
    case uninstall(name: String, kind: PackageKind)
    case cleanup

    public var id: String { commandDisplay }

    public var title: String {
        switch self {
        case .update: return "Update Homebrew"
        case .upgrade(let name, _): return "Upgrade \(name)"
        case .install(let name, _): return "Install \(name)"
        case .uninstall(let name, _): return "Uninstall \(name)"
        case .cleanup: return "Clean Up Homebrew"
        }
    }

    public var isMutating: Bool { true }

    public var arguments: [String] {
        switch self {
        case .update:
            return ["update"]
        case .upgrade(let name, let kind):
            return kind == .cask ? ["upgrade", "--cask", name] : ["upgrade", name]
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
