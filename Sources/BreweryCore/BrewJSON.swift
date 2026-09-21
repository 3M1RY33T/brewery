import Foundation

struct BrewInfoPayload: Decodable {
    let formulae: [FormulaInfo]
    let casks: [CaskInfo]

    init(from decoder: Decoder) throws {
        if let keyed = try? decoder.container(keyedBy: CodingKeys.self) {
            formulae = try keyed.decodeIfPresent([FormulaInfo].self, forKey: .formulae) ?? []
            casks = try keyed.decodeIfPresent([CaskInfo].self, forKey: .casks) ?? []
            return
        }

        let single = try decoder.singleValueContainer()
        formulae = try single.decode([FormulaInfo].self)
        casks = []
    }

    private enum CodingKeys: String, CodingKey {
        case formulae
        case casks
    }
}

struct FormulaInfo: Decodable {
    struct Versions: Decodable {
        let stable: String?
    }

    struct Installed: Decodable {
        struct RuntimeDependency: Decodable {
            let fullName: String
            let declaredDirectly: Bool?

            var packageName: String {
                fullName.split(separator: "/").last.map(String.init) ?? fullName
            }

            private enum CodingKeys: String, CodingKey {
                case fullName = "full_name"
                case declaredDirectly = "declared_directly"
            }
        }

        let version: String?
        let installedAsDependency: Bool?
        let installedOnRequest: Bool?
        let runtimeDependencies: [RuntimeDependency]

        private enum CodingKeys: String, CodingKey {
            case version
            case installedAsDependency = "installed_as_dependency"
            case installedOnRequest = "installed_on_request"
            case runtimeDependencies = "runtime_dependencies"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            version = try container.decodeIfPresent(String.self, forKey: .version)
            installedAsDependency = try container.decodeIfPresent(Bool.self, forKey: .installedAsDependency)
            installedOnRequest = try container.decodeIfPresent(Bool.self, forKey: .installedOnRequest)
            runtimeDependencies = try container.decodeIfPresent([RuntimeDependency].self, forKey: .runtimeDependencies) ?? []
        }
    }

    let name: String
    let fullName: String?
    let tap: String?
    let desc: String?
    let homepage: String?
    let versions: Versions?
    let installed: [Installed]
    let linkedKeg: String?
    let pinned: Bool?
    let outdated: Bool?
    let caveats: String?
    let dependencies: [String]?

    private enum CodingKeys: String, CodingKey {
        case name
        case fullName = "full_name"
        case tap
        case desc
        case homepage
        case versions
        case installed
        case linkedKeg = "linked_keg"
        case pinned
        case outdated
        case caveats
        case dependencies
    }
}

struct CaskInfo: Decodable {
    let token: String
    let fullToken: String?
    let tap: String?
    let name: FlexibleStringList?
    let desc: String?
    let homepage: String?
    let version: String?
    let installed: FlexibleStringList?
    let installedTime: Int?
    let pinned: Bool?
    let outdated: Bool?
    let caveats: String?
    let dependsOn: FlexibleDependencyMap?
    let artifacts: CaskArtifacts?

    private enum CodingKeys: String, CodingKey {
        case token
        case fullToken = "full_token"
        case tap
        case name
        case desc
        case homepage
        case version
        case installed
        case installedTime = "installed_time"
        case pinned
        case outdated
        case caveats
        case dependsOn = "depends_on"
        case artifacts
    }
}

struct FlexibleStringList: Decodable, Equatable {
    let values: [String]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            values = []
        } else if let value = try? container.decode(String.self) {
            values = [value]
        } else {
            values = try container.decode([String].self)
        }
    }
}

struct CaskDependency: Equatable {
    let kind: PackageKind
    let name: String
}

struct FlexibleDependencyMap: Decodable, Equatable {
    let values: [CaskDependency]

    init(from decoder: Decoder) throws {
        guard let keyed = try? decoder.container(keyedBy: DynamicCodingKey.self) else {
            values = []
            return
        }

        var dependencies: [CaskDependency] = []
        for key in keyed.allKeys {
            let kind: PackageKind?
            switch key.stringValue {
            case "formula":
                kind = .formula
            case "cask":
                kind = .cask
            default:
                kind = nil
            }

            guard let kind else { continue }
            let names = (try? keyed.decode(FlexibleDependencyValue.self, forKey: key).values) ?? []
            dependencies += names.map { CaskDependency(kind: kind, name: $0) }
        }
        values = dependencies
    }
}

struct FlexibleDependencyValue: Decodable, Equatable {
    let values: [String]

    init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer(), container.decodeNil() {
            values = []
        } else if let container = try? decoder.singleValueContainer(), let value = try? container.decode(String.self) {
            values = [value]
        } else if var unkeyed = try? decoder.unkeyedContainer() {
            var dependencies: [String] = []
            while !unkeyed.isAtEnd {
                if let value = try? unkeyed.decode(String.self) {
                    dependencies.append(value)
                } else {
                    _ = try? unkeyed.decode(IgnoredJSONValue.self)
                }
            }
            values = dependencies
        } else if let keyed = try? decoder.container(keyedBy: DynamicCodingKey.self) {
            var dependencies: [String] = []
            for key in keyed.allKeys {
                dependencies += (try? keyed.decode(FlexibleDependencyValue.self, forKey: key).values) ?? []
            }
            values = dependencies
        } else {
            values = []
        }
    }
}

struct IgnoredJSONValue: Decodable {}

struct DynamicCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

struct OutdatedPayload: Decodable {
    let formulae: [OutdatedItem]
    let casks: [OutdatedItem]
}

struct OutdatedItem: Decodable {
    let name: String
    let currentVersion: String?
    let installedVersions: [String]
    let pinned: Bool?

    private enum CodingKeys: String, CodingKey {
        case name
        case token
        case currentVersion = "current_version"
        case installedVersions = "installed_versions"
        case pinned
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name)
            ?? container.decode(String.self, forKey: .token)
        currentVersion = try container.decodeIfPresent(String.self, forKey: .currentVersion)
        installedVersions = try container.decodeIfPresent([String].self, forKey: .installedVersions) ?? []
        pinned = try container.decodeIfPresent(Bool.self, forKey: .pinned)
    }
}

enum BrewPackageMapper {
    static func inventory(from info: BrewInfoPayload, outdated: OutdatedPayload?) -> BrewInventory {
        let outdatedFormulae = Dictionary(uniqueKeysWithValues: (outdated?.formulae ?? []).map { ($0.name, $0) })
        let outdatedCasks = Dictionary(uniqueKeysWithValues: (outdated?.casks ?? []).map { ($0.name, $0) })
        var edges: [DependencyEdge] = []

        let formulae = info.formulae.map { formula in
            let outdatedItem = outdatedFormulae[formula.name]
            let installedRuntimeDependencies = formula.installed.flatMap(\.runtimeDependencies)
            let directRuntimeDependencies = installedRuntimeDependencies.filter { $0.declaredDirectly == true }
            let packageDependencies = directRuntimeDependencies.isEmpty
                ? (formula.dependencies ?? [])
                : directRuntimeDependencies.map(\.packageName)
            let source = PackageNodeID(kind: .formula, name: formula.name)

            edges += installedRuntimeDependencies.map { dependency in
                DependencyEdge(
                    from: source,
                    to: PackageNodeID(kind: .formula, name: dependency.packageName),
                    relationship: dependency.declaredDirectly == true ? .direct : .runtime
                )
            }

            return BrewPackage(
                name: formula.name,
                displayName: formula.fullName ?? formula.name,
                kind: .formula,
                tap: formula.tap,
                description: formula.desc,
                homepage: formula.homepage.flatMap(URL.init(string:)),
                installedVersion: formula.installed.first?.version ?? outdatedItem?.installedVersions.first,
                currentVersion: outdatedItem?.currentVersion ?? formula.versions?.stable,
                dependencies: Array(Set(packageDependencies)).sorted(),
                caveats: formula.caveats,
                installedPaths: formula.linkedKeg.map { [$0] } ?? [],
                pinned: outdatedItem?.pinned ?? formula.pinned ?? false,
                outdated: outdatedItem != nil || formula.outdated == true
            )
        }

        let casks = info.casks.map { cask in
            let outdatedItem = outdatedCasks[cask.token]
            let source = PackageNodeID(kind: .cask, name: cask.token)
            let caskDependencies = cask.dependsOn?.values ?? []
            edges += caskDependencies.map { dependency in
                DependencyEdge(
                    from: source,
                    to: PackageNodeID(kind: dependency.kind, name: dependency.name),
                    relationship: .caskDeclared
                )
            }

            return BrewPackage(
                name: cask.token,
                displayName: cask.name?.values.first ?? cask.fullToken ?? cask.token,
                kind: .cask,
                tap: cask.tap,
                description: cask.desc,
                homepage: cask.homepage.flatMap(URL.init(string:)),
                installedVersion: cask.installed?.values.first ?? outdatedItem?.installedVersions.first,
                currentVersion: outdatedItem?.currentVersion ?? cask.version,
                dependencies: caskDependencies.map(\.name).sorted(),
                caveats: cask.caveats,
                installedPaths: [],
                appBundleName: cask.artifacts?.appBundleName,
                pinned: outdatedItem?.pinned ?? cask.pinned ?? false,
                outdated: outdatedItem != nil || cask.outdated == true
            )
        }

        return (formulae + casks).sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }.withGraph(edges: edges)
    }

    static func packages(from info: BrewInfoPayload, outdated: OutdatedPayload?) -> [BrewPackage] {
        inventory(from: info, outdated: outdated).packages
    }
}

private extension Array where Element == BrewPackage {
    func withGraph(edges: [DependencyEdge]) -> BrewInventory {
        let nodes = Set(map(\.nodeID))
        return BrewInventory(packages: self, graph: BrewDependencyGraph(nodes: nodes, edges: edges))
    }
}
