import Foundation

struct FormulaCatalogItem: Decodable {
    struct Versions: Decodable {
        let stable: String?
    }

    let name: String
    let fullName: String?
    let tap: String?
    let desc: String?
    let homepage: String?
    let versions: Versions?
    let dependencies: [String]?

    private enum CodingKeys: String, CodingKey {
        case name
        case fullName = "full_name"
        case tap
        case desc
        case homepage
        case versions
        case dependencies
    }
}

struct CaskCatalogItem: Decodable {
    let token: String
    let fullToken: String?
    let tap: String?
    let name: FlexibleStringList?
    let desc: String?
    let homepage: String?
    let version: String?
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
        case dependsOn = "depends_on"
        case artifacts
    }
}

/// One row of Homebrew's install analytics.
struct AnalyticsItem: Decodable {
    let formula: String?
    let cask: String?
    let count: String

    var name: String? { formula ?? cask }

    /// Counts arrive as display strings such as `"5,535,528"`.
    var installs: Int {
        Int(count.filter(\.isNumber)) ?? 0
    }
}

struct AnalyticsPayload: Decodable {
    let items: [AnalyticsItem]
}

enum CatalogPackageMapper {
    /// Install counts keyed by package name, for ordering the browse shelves.
    static func installCounts(from data: Data, kind: PackageKind) throws -> [String: Int] {
        let payload = try JSONDecoder().decode(AnalyticsPayload.self, from: data)
        var counts: [String: Int] = [:]
        for item in payload.items {
            guard let name = item.name else { continue }
            // Analytics can list a name more than once; keep the largest.
            counts[name] = max(counts[name] ?? 0, item.installs)
        }
        return counts
    }

    static func formulaPackages(
        from data: Data,
        popularity: [String: Int] = [:]
    ) throws -> [CatalogPackage] {
        try JSONDecoder().decode([FormulaCatalogItem].self, from: data).map { formula in
            CatalogPackage(
                name: formula.name,
                displayName: formula.fullName ?? formula.name,
                kind: .formula,
                description: formula.desc,
                homepage: formula.homepage.flatMap(URL.init(string:)),
                version: formula.versions?.stable,
                tap: formula.tap,
                dependencies: formula.dependencies ?? [],
                popularity: popularity[formula.name] ?? 0
            )
        }
    }

    static func caskPackages(
        from data: Data,
        popularity: [String: Int] = [:]
    ) throws -> [CatalogPackage] {
        try JSONDecoder().decode([CaskCatalogItem].self, from: data).map { cask in
            CatalogPackage(
                name: cask.token,
                displayName: cask.name?.values.first ?? cask.fullToken ?? cask.token,
                kind: .cask,
                description: cask.desc,
                homepage: cask.homepage.flatMap(URL.init(string:)),
                version: cask.version,
                tap: cask.tap,
                dependencies: cask.dependsOn?.values.map(\.name).sorted() ?? [],
                appBundleName: cask.artifacts?.appBundleName,
                popularity: popularity[cask.token] ?? 0
            )
        }
    }
}
