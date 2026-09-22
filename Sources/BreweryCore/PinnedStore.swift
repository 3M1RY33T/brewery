import Combine
import Foundation

/// Catalog entries the user has pinned to come back to.
///
/// This is Brewery's own list, not `brew pin`: Homebrew's pin holds an
/// installed formula at its version, whereas this remembers any package in
/// the catalog, installed or not, cask or formula. Kept in user defaults, so
/// it survives launches and needs no network.
@MainActor
public final class PinnedStore: ObservableObject {
    @Published public private(set) var ids: Set<String>

    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = "pinnedCatalogPackages") {
        self.defaults = defaults
        self.key = key
        ids = Set(defaults.stringArray(forKey: key) ?? [])
    }

    public var count: Int { ids.count }
    public var isEmpty: Bool { ids.isEmpty }

    public func isPinned(_ id: String) -> Bool {
        ids.contains(id)
    }

    public func toggle(_ id: String) {
        if ids.contains(id) {
            ids.remove(id)
        } else {
            ids.insert(id)
        }
        save()
    }

    /// The pinned packages that exist in `packages`, in that order.
    public func pinned(in packages: [CatalogPackage]) -> [CatalogPackage] {
        guard !ids.isEmpty else { return [] }
        return packages.filter { ids.contains($0.id) }
    }

    private func save() {
        // Sorted so the stored form is stable and diffs cleanly.
        defaults.set(ids.sorted(), forKey: key)
    }
}
