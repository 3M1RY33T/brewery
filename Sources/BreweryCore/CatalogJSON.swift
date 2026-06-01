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

    private enum CodingKeys: String, CodingKey {
        case token
        case fullToken = "full_token"
        case tap
        case name
        case desc
        case homepage
        case version
        case dependsOn = "depends_on"
    }
}

enum CatalogPackageMapper {
    static func formulaPackages(from data: Data) throws -> [CatalogPackage] {
        try JSONDecoder().decode([FormulaCatalogItem].self, from: data).map { formula in
            CatalogPackage(
                name: formula.name,
                displayName: formula.fullName ?? formula.name,
                kind: .formula,
                description: formula.desc,
                homepage: formula.homepage.flatMap(URL.init(string:)),
                version: formula.versions?.stable,
                tap: formula.tap,
                dependencies: formula.dependencies ?? []
            )
        }
    }

    static func caskPackages(from data: Data) throws -> [CatalogPackage] {
        try JSONDecoder().decode([CaskCatalogItem].self, from: data).map { cask in
            CatalogPackage(
                name: cask.token,
                displayName: cask.name?.values.first ?? cask.fullToken ?? cask.token,
                kind: .cask,
                description: cask.desc,
                homepage: cask.homepage.flatMap(URL.init(string:)),
                version: cask.version,
                tap: cask.tap,
                dependencies: cask.dependsOn?.values.map(\.name).sorted() ?? []
            )
        }
    }
}
