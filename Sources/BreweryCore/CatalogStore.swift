import Combine
import Foundation

public protocol CatalogFetching {
    func data(from url: URL) async throws -> Data
}

public struct URLSessionCatalogFetcher: CatalogFetching {
    public init() {}

    public func data(from url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            throw CatalogError.httpStatus(httpResponse.statusCode)
        }
        return data
    }
}

public enum CatalogError: LocalizedError, Equatable {
    case httpStatus(Int)
    case noCachedCatalog

    public var errorDescription: String? {
        switch self {
        case .httpStatus(let status):
            return "Catalog request failed with HTTP \(status)."
        case .noCachedCatalog:
            return "No cached catalog is available."
        }
    }
}

@MainActor
public final class CatalogStore: ObservableObject {
    @Published public private(set) var packages: [CatalogPackage] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var statusMessage = "Catalog not loaded"
    @Published public var searchText = ""
    @Published public var kindFilter: CatalogKindFilter = .all {
        didSet {
            normalizeCategory()
        }
    }
    @Published public var category: CatalogCategory = .featured

    private let fetcher: CatalogFetching
    private let cacheURL: URL
    private let formulaURL: URL
    private let caskURL: URL
    private let cacheLifetime: TimeInterval

    public init(
        fetcher: CatalogFetching = URLSessionCatalogFetcher(),
        cacheURL: URL = CatalogStore.defaultCacheURL(),
        formulaURL: URL = URL(string: "https://formulae.brew.sh/api/formula.json")!,
        caskURL: URL = URL(string: "https://formulae.brew.sh/api/cask.json")!,
        cacheLifetime: TimeInterval = 60 * 60 * 18
    ) {
        self.fetcher = fetcher
        self.cacheURL = cacheURL
        self.formulaURL = formulaURL
        self.caskURL = caskURL
        self.cacheLifetime = cacheLifetime
    }

    public var filteredPackages: [CatalogPackage] {
        CatalogSearch.filter(
            packages,
            searchText: searchText,
            kindFilter: kindFilter,
            category: category
        )
    }

    public func load(installedPackages: [BrewPackage], forceRefresh: Bool = false) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let snapshot = try forceRefresh ? await fetchCatalog() : await loadCachedOrFetch()
            packages = CatalogSearch.merge(snapshot.packages, installedPackages: installedPackages)
            statusMessage = "Loaded \(packages.count) catalog items"
        } catch {
            if let cached = try? loadCachedSnapshot() {
                packages = CatalogSearch.merge(cached.packages, installedPackages: installedPackages)
                statusMessage = "Using cached catalog"
            } else {
                statusMessage = error.localizedDescription
            }
        }
    }

    public func mergeInstalledState(_ installedPackages: [BrewPackage]) {
        packages = CatalogSearch.merge(packages, installedPackages: installedPackages)
    }

    public func normalizeCategory() {
        guard !CatalogCategory.available(for: kindFilter).contains(category) else { return }
        category = .featured
    }

    private func loadCachedOrFetch() async throws -> CatalogSnapshot {
        if let cached = try? loadCachedSnapshot(), Date().timeIntervalSince(cached.fetchedAt) < cacheLifetime {
            return cached
        }
        return try await fetchCatalog()
    }

    private func fetchCatalog() async throws -> CatalogSnapshot {
        async let formulaData = fetcher.data(from: formulaURL)
        async let caskData = fetcher.data(from: caskURL)

        let packages = try await CatalogPackageMapper.formulaPackages(from: formulaData)
            + CatalogPackageMapper.caskPackages(from: caskData)
        let snapshot = CatalogSnapshot(
            fetchedAt: Date(),
            packages: packages.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        )
        try save(snapshot)
        return snapshot
    }

    private func loadCachedSnapshot() throws -> CatalogSnapshot {
        let data = try Data(contentsOf: cacheURL)
        return try JSONDecoder().decode(CatalogSnapshot.self, from: data)
    }

    private func save(_ snapshot: CatalogSnapshot) throws {
        try FileManager.default.createDirectory(at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(snapshot)
        try data.write(to: cacheURL, options: [.atomic])
    }

    public nonisolated static func defaultCacheURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return base
            .appendingPathComponent("Brewery", isDirectory: true)
            .appendingPathComponent("catalog-cache.json")
    }
}

public enum CatalogSearch {
    public static func merge(_ packages: [CatalogPackage], installedPackages: [BrewPackage]) -> [CatalogPackage] {
        let installed = Dictionary(uniqueKeysWithValues: installedPackages.map { ($0.nodeID, $0) })
        return packages.map { package in
            var merged = package
            if let installedPackage = installed[package.nodeID] {
                merged.installStatus = .installed(outdated: installedPackage.outdated)
            } else {
                merged.installStatus = .notInstalled
            }
            return merged
        }
    }

    public static func filter(
        _ packages: [CatalogPackage],
        searchText: String,
        kindFilter: CatalogKindFilter,
        category: CatalogCategory
    ) -> [CatalogPackage] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return packages
            .filter { package in
                switch kindFilter {
                case .all:
                    return true
                case .casks:
                    return package.kind == .cask
                case .formulae:
                    return package.kind == .formula
                }
            }
            .filter { package in
                category == .featured || package.categoryScore(for: category) > 0
            }
            .filter { package in
                query.isEmpty || package.searchIndex.contains(query)
            }
            .sorted { lhs, rhs in
                let left = rank(lhs, query: query, category: category)
                let right = rank(rhs, query: query, category: category)
                if left != right { return left > right }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    private static func rank(_ package: CatalogPackage, query: String, category: CatalogCategory) -> Int {
        var score = package.categoryScore(for: category)
        guard !query.isEmpty else { return score }

        let name = package.name.lowercased()
        let displayName = package.displayName.lowercased()
        if name == query { score += 100 }
        if displayName == query { score += 90 }
        if name.hasPrefix(query) { score += 60 }
        if displayName.hasPrefix(query) { score += 50 }
        if package.searchIndex.contains(query) { score += 10 }
        return score
    }
}
