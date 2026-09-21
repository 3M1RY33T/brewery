import Foundation

/// Builds the browse shelves and answers searches.
public enum CatalogSearch {
    /// How many of each kind a shelf shows before it is truncated.
    public static let defaultCaskLimit = 16
    public static let defaultFormulaLimit = 8

    public static func merge(_ packages: [CatalogPackage], installedPackages: [BrewPackage]) -> [CatalogPackage] {
        let installed = installedStatuses(installedPackages)
        return packages.map { $0.withInstallStatus(installed[$0.nodeID] ?? .notInstalled) }
    }

    /// Reapplies install status to already built shelves.
    ///
    /// Shelves are capped, so this touches a few hundred packages rather than
    /// rescoring the whole catalog every time an install finishes.
    public static func merge(_ sections: [CatalogSection], installedPackages: [BrewPackage]) -> [CatalogSection] {
        let installed = installedStatuses(installedPackages)
        return sections.map { section in
            CatalogSection(
                category: section.category,
                casks: section.casks.map { $0.withInstallStatus(installed[$0.nodeID] ?? .notInstalled) },
                formulae: section.formulae.map { $0.withInstallStatus(installed[$0.nodeID] ?? .notInstalled) },
                caskTotal: section.caskTotal,
                formulaTotal: section.formulaTotal
            )
        }
    }

    private static func installedStatuses(_ installedPackages: [BrewPackage]) -> [PackageNodeID: CatalogInstallStatus] {
        Dictionary(uniqueKeysWithValues: installedPackages.map {
            ($0.nodeID, CatalogInstallStatus.installed(outdated: $0.outdated))
        })
    }

    /// The category a package belongs to. Every package gets exactly one, so
    /// a shelf never repeats what another shelf already showed.
    public static func category(for package: CatalogPackage) -> CatalogCategory {
        let text = package.searchIndex
        let tokens = self.tokens(in: text)

        var best: (category: CatalogCategory, score: Int)?
        for candidate in CatalogCategory.assignable {
            let score = candidate.score(tokens: tokens, text: text)
            guard score > 0 else { continue }
            // Ties go to the earlier category, which is the more specific one.
            if score > (best?.score ?? 0) {
                best = (candidate, score)
            }
        }
        return best?.category ?? .utilities
    }

    /// The full set of shelves, most installed first within each.
    public static func sections(
        _ packages: [CatalogPackage],
        caskLimit: Int = defaultCaskLimit,
        formulaLimit: Int = defaultFormulaLimit
    ) -> [CatalogSection] {
        let ranked = packages.sorted(by: isMorePopular)

        var grouped: [CatalogCategory: (casks: [CatalogPackage], formulae: [CatalogPackage])] = [:]
        for package in ranked {
            let category = category(for: package)
            if package.kind == .cask {
                grouped[category, default: ([], [])].casks.append(package)
            } else {
                grouped[category, default: ([], [])].formulae.append(package)
            }
        }

        // Featured is a ranking across everything, not a subject of its own.
        let featured = CatalogSection(
            category: .featured,
            casks: Array(ranked.lazy.filter { $0.kind == .cask }.prefix(caskLimit)),
            formulae: Array(ranked.lazy.filter { $0.kind == .formula }.prefix(formulaLimit)),
            caskTotal: ranked.lazy.filter { $0.kind == .cask }.count,
            formulaTotal: ranked.lazy.filter { $0.kind == .formula }.count
        )

        let rest = CatalogCategory.allCases
            .filter { $0 != .featured }
            .map { category -> CatalogSection in
                let bucket = grouped[category] ?? ([], [])
                return CatalogSection(
                    category: category,
                    casks: Array(bucket.casks.prefix(caskLimit)),
                    formulae: Array(bucket.formulae.prefix(formulaLimit)),
                    caskTotal: bucket.casks.count,
                    formulaTotal: bucket.formulae.count
                )
            }

        return ([featured] + rest).filter { !$0.isEmpty }
    }

    /// Everything matching `searchText`, split by kind.
    public static func searchResults(
        _ packages: [CatalogPackage],
        searchText: String,
        limitPerKind: Int = 60
    ) -> CatalogSearchResults {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return CatalogSearchResults(casks: [], formulae: []) }

        let matches = packages
            .filter { $0.searchIndex.contains(query) }
            .sorted { lhs, rhs in
                let left = rank(lhs, query: query)
                let right = rank(rhs, query: query)
                if left != right { return left > right }
                return isMorePopular(lhs, rhs)
            }

        return CatalogSearchResults(
            casks: Array(matches.lazy.filter { $0.kind == .cask }.prefix(limitPerKind)),
            formulae: Array(matches.lazy.filter { $0.kind == .formula }.prefix(limitPerKind))
        )
    }

    private static func isMorePopular(_ lhs: CatalogPackage, _ rhs: CatalogPackage) -> Bool {
        if lhs.popularity != rhs.popularity { return lhs.popularity > rhs.popularity }
        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }

    private static func rank(_ package: CatalogPackage, query: String) -> Int {
        var score = 0
        let name = package.name.lowercased()
        let displayName = package.displayName.lowercased()
        if name == query { score += 100 }
        if displayName == query { score += 90 }
        if name.hasPrefix(query) { score += 60 }
        if displayName.hasPrefix(query) { score += 50 }
        if package.searchIndex.contains(query) { score += 10 }
        return score
    }

    static func tokens(in text: String) -> Set<String> {
        Set(text.split { !$0.isLetter && !$0.isNumber }.map(String.init))
    }
}
