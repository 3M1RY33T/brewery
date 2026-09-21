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
    case staleCacheFormat

    public var errorDescription: String? {
        switch self {
        case .httpStatus(let status):
            return "Catalog request failed with HTTP \(status)."
        case .noCachedCatalog:
            return "No cached catalog is available."
        case .staleCacheFormat:
            return "The cached catalog was written by an older version of Brewery."
        }
    }
}

@MainActor
public final class CatalogStore: ObservableObject {
    @Published public private(set) var packages: [CatalogPackage] = []
    /// The browse shelves, rebuilt only when the catalog itself changes.
    @Published public private(set) var sections: [CatalogSection] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var statusMessage = "Catalog not loaded"
    @Published public var searchText = ""

    private let fetcher: CatalogFetching
    private let cacheURL: URL
    private let formulaURL: URL
    private let caskURL: URL
    private let formulaAnalyticsURL: URL
    private let caskAnalyticsURL: URL
    private let cacheLifetime: TimeInterval

    public init(
        fetcher: CatalogFetching = URLSessionCatalogFetcher(),
        cacheURL: URL = CatalogStore.defaultCacheURL(),
        formulaURL: URL = URL(string: "https://formulae.brew.sh/api/formula.json")!,
        caskURL: URL = URL(string: "https://formulae.brew.sh/api/cask.json")!,
        formulaAnalyticsURL: URL = URL(string: "https://formulae.brew.sh/api/analytics/install/365d.json")!,
        caskAnalyticsURL: URL = URL(string: "https://formulae.brew.sh/api/analytics/cask-install/365d.json")!,
        cacheLifetime: TimeInterval = 60 * 60 * 18
    ) {
        self.fetcher = fetcher
        self.cacheURL = cacheURL
        self.formulaURL = formulaURL
        self.caskURL = caskURL
        self.formulaAnalyticsURL = formulaAnalyticsURL
        self.caskAnalyticsURL = caskAnalyticsURL
        self.cacheLifetime = cacheLifetime
    }

    public var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var searchResults: CatalogSearchResults {
        CatalogSearch.searchResults(packages, searchText: searchText)
    }

    public func load(installedPackages: [BrewPackage], forceRefresh: Bool = false) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let snapshot = try forceRefresh ? await fetchCatalog() : await loadCachedOrFetch()
            apply(snapshot, installedPackages: installedPackages)
            statusMessage = "Loaded \(packages.count) catalog items"
        } catch {
            if let cached = try? loadCachedSnapshot() {
                apply(cached, installedPackages: installedPackages)
                statusMessage = "Using cached catalog"
            } else {
                statusMessage = error.localizedDescription
            }
        }
    }

    public func mergeInstalledState(_ installedPackages: [BrewPackage]) {
        packages = CatalogSearch.merge(packages, installedPackages: installedPackages)
        sections = CatalogSearch.merge(sections, installedPackages: installedPackages)
    }

    private func apply(_ snapshot: CatalogSnapshot, installedPackages: [BrewPackage]) {
        packages = CatalogSearch.merge(snapshot.packages, installedPackages: installedPackages)
        sections = CatalogSearch.sections(packages)
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
        // Analytics only order the shelves, so a failure here must not cost
        // the user the catalog itself.
        async let formulaAnalytics = try? fetcher.data(from: formulaAnalyticsURL)
        async let caskAnalytics = try? fetcher.data(from: caskAnalyticsURL)

        let formulaPopularity = await formulaAnalytics.flatMap {
            try? CatalogPackageMapper.installCounts(from: $0, kind: .formula)
        } ?? [:]
        let caskPopularity = await caskAnalytics.flatMap {
            try? CatalogPackageMapper.installCounts(from: $0, kind: .cask)
        } ?? [:]

        let packages = try await CatalogPackageMapper.formulaPackages(from: formulaData, popularity: formulaPopularity)
            + CatalogPackageMapper.caskPackages(from: caskData, popularity: caskPopularity)

        let snapshot = CatalogSnapshot(
            fetchedAt: Date(),
            packages: packages.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        )
        try save(snapshot)
        return snapshot
    }

    private func loadCachedSnapshot() throws -> CatalogSnapshot {
        let data = try Data(contentsOf: cacheURL)
        let snapshot = try JSONDecoder().decode(CatalogSnapshot.self, from: data)
        guard snapshot.isCurrent else { throw CatalogError.staleCacheFormat }
        return snapshot
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
