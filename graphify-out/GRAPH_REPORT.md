# Graph Report - brewery  (2026-09-22)

## Corpus Check
- 44 files · ~228,705 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 740 nodes · 1751 edges · 39 communities (36 shown, 3 thin omitted)
- Extraction: 91% EXTRACTED · 9% INFERRED · 0% AMBIGUOUS · INFERRED: 157 edges (avg confidence: 0.83)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `3fabb341`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- PackageStore
- String
- PackageNodeID
- BreweryCoreTests
- LiveBrewService
- PinnedStore
- CatalogCategory
- BrewPackage
- PackageIconView
- .sources
- BrowseShelves.swift
- View
- BreweryCore
- README.md
- CategoryTileGrid
- InstalledCaskCard
- CursorTrackingView
- InstalledPackagesView
- CatalogSearchResults
- Package.swift
- build-app.sh
- run-app.sh
- CodingKeys
- CatalogStore
- BrowseView
- Foundation
- CodingKeys
- CodingKeys
- CatalogPackage
- BrewAction
- BrowseView.swift
- .fixture
- InstallSheet
- Decodable
- Equatable
- CatalogError
- .formulaPackages
- .packages
- AnalyticsItem

## God Nodes (most connected - your core abstractions)
1. `CatalogPackage` - 67 edges
2. `BreweryCoreTests` - 49 edges
3. `BrewPackage` - 48 edges
4. `PackageNodeID` - 44 edges
5. `PackageStore` - 38 edges
6. `BrewAction` - 34 edges
7. `CodingKeys` - 34 edges
8. `CatalogCategory` - 33 edges
9. `CatalogStore` - 33 edges
10. `PackageIconView` - 25 edges

## Surprising Connections (you probably didn't know these)
- `StubFileManager` --references--> `String`  [EXTRACTED]
  Tests/BreweryCoreTests/BreweryCoreTests.swift → Sources/BreweryCore/BrewDetector.swift
- `.filteredPackages` --references--> `BrewPackage`  [INFERRED]
  Sources/BreweryCore/PackageStore.swift → Sources/BreweryCore/BrewPackage.swift
- `.selectedPackage` --references--> `BrewPackage`  [INFERRED]
  Sources/BreweryCore/PackageStore.swift → Sources/BreweryCore/BrewPackage.swift
- `MockCatalogFetcher` --implements--> `CatalogFetching`  [EXTRACTED]
  Tests/BreweryCoreTests/BreweryCoreTests.swift → Sources/BreweryCore/CatalogStore.swift
- `BreweryApp` --calls--> `PinnedStore`  [INFERRED]
  Sources/Brewery/BreweryApp.swift → Sources/BreweryCore/PinnedStore.swift

## Import Cycles
- None detected.

## Communities (39 total, 3 thin omitted)

### Community 0 - "PackageStore"
Cohesion: 0.07
Nodes (35): AnyObject, App, Gesture, Scene, BreweryApp, .body, CommandLogView, .body (+27 more)

### Community 1 - "String"
Cohesion: 0.19
Nodes (11): CodingKey, String, .nilIfEmpty, DynamicCodingKey, Int, CaskAppArtifact, CaskAppArtifactEntry, CaskArtifactEntry (+3 more)

### Community 2 - "PackageNodeID"
Cohesion: 0.12
Nodes (18): Codable, Comparable, Hashable, KeyPath, .body, BrewDependencyGraph, BrewInventory, DependencyEdge (+10 more)

### Community 3 - "BreweryCoreTests"
Cohesion: 0.15
Nodes (3): BreweryCoreTests, Int, XCTestCase

### Community 4 - "LiveBrewService"
Cohesion: 0.05
Nodes (33): CoreGraphics, FileManager, Int32, JSONDecoder, BrewDetectionReport, .isAvailable, BrewDetector, Bool (+25 more)

### Community 5 - "PinnedStore"
Cohesion: 0.15
Nodes (11): ObservableObject, .body, DetailPinButton, .body, PinnedStore, .count, .isEmpty, Bool (+3 more)

### Community 6 - "CatalogCategory"
Cohesion: 0.05
Nodes (43): CaseIterable, Identifiable, PackageKind, cask, formula, .id, .title, PackageFilter (+35 more)

### Community 7 - "BrewPackage"
Cohesion: 0.43
Nodes (4): Array, BrewPackage, Bool, URL

### Community 8 - "PackageIconView"
Cohesion: 0.08
Nodes (29): ImageIO, Never, Sendable, NSImage, PackageIconLoader, PackageIconView, .body, .glyph (+21 more)

### Community 9 - ".sources"
Cohesion: 0.16
Nodes (8): PackageIconResolver, PackageIconSource, appBundle, remote, Bool, FileManager, Set, URL

### Community 10 - "BrowseShelves.swift"
Cohesion: 0.16
Nodes (26): .grid, ChartRow, .body, Color, CompactCell, .body, CompactIconGrid, .body (+18 more)

### Community 11 - "View"
Cohesion: 0.20
Nodes (12): CatalogPackageDetailView, .body, Bool, DependencyNodeList, DetailBlock, .body, DetailRow, .body (+4 more)

### Community 12 - "BreweryCore"
Cohesion: 0.19
Nodes (7): BreweryCore, DetailPaneResizeHandle, DiagnosticsBlock, .body, MissingHomebrewView, .body, SwiftUI

### Community 13 - "README.md"
Cohesion: 0.17
Nodes (11): Browse the whole catalog, Build from source, Credits, Diagnostics, Features, Install, [Install Homebrew on macOS:](https://brew.sh/), Notes (+3 more)

### Community 14 - "CategoryTileGrid"
Cohesion: 0.14
Nodes (15): CategoryTileGrid, .body, .canToggle, .collapsedCount, .columnCount, ShowMoreButton, .body, CGFloat (+7 more)

### Community 15 - "InstalledCaskCard"
Cohesion: 0.22
Nodes (10): InstalledCaskCard, .body, InstalledVersionLabel, .body, Bool, Int, Void, .body (+2 more)

### Community 16 - "CursorTrackingView"
Cohesion: 0.10
Nodes (15): AppKit, NSEvent, NSObjectProtocol, NSTrackingArea, NSView, NSViewRepresentable, NSWindow, CursorTrackingView (+7 more)

### Community 17 - "InstalledPackagesView"
Cohesion: 0.15
Nodes (14): Accessory, Content, InstalledCasksSheet, .body, InstalledFormulaRow, InstalledPackagesView, .body, .caskRow (+6 more)

### Community 18 - "CatalogSearchResults"
Cohesion: 0.17
Nodes (6): CatalogSearchResults, .isEmpty, CatalogSearch, Bool, Int, Set

### Community 22 - "CodingKeys"
Cohesion: 0.07
Nodes (27): CodingKeys, artifacts, casks, caveats, currentVersion, declaredDirectly, dependencies, dependsOn (+19 more)

### Community 23 - "CatalogStore"
Cohesion: 0.25
Nodes (8): CatalogSnapshot, .isCurrent, CatalogStore, .isSearching, .searchResults, Bool, TimeInterval, URL

### Community 24 - "BrowseView"
Cohesion: 0.21
Nodes (9): ScrollViewProxy, ShelfHeader, .body, BrowseView, .body, .header, .pinnedResults, .body (+1 more)

### Community 25 - "Foundation"
Cohesion: 0.25
Nodes (4): Combine, Foundation, CatalogFetching, URLSessionCatalogFetcher

### Community 26 - "CodingKeys"
Cohesion: 0.20
Nodes (10): CodingKeys, appBundleName, dependencies, description, displayName, homepage, kind, name (+2 more)

### Community 27 - "CodingKeys"
Cohesion: 0.15
Nodes (13): CodingKeys, artifacts, dependencies, dependsOn, desc, fullName, fullToken, homepage (+5 more)

### Community 28 - "CatalogPackage"
Cohesion: 0.16
Nodes (15): Encoder, .visible, CatalogInstallStatus, installed, notInstalled, .title, CatalogPackage, CatalogSection (+7 more)

### Community 29 - "BrewAction"
Cohesion: 0.13
Nodes (13): BrewAction, .arguments, cleanup, .commandDisplay, .id, install, .isMutating, .title (+5 more)

### Community 30 - "BrowseView.swift"
Cohesion: 0.16
Nodes (20): PreferenceKey, .searchResults, CaskShelfRow, .body, CatalogCard, .body, CatalogShelf, .casks (+12 more)

### Community 31 - ".fixture"
Cohesion: 0.29
Nodes (7): Error, IconError, unusable, MockCatalogFetcher, NotStubbed, Data, URL

### Community 32 - "InstallSheet"
Cohesion: 0.40
Nodes (5): ConfirmationSheet, .body, InstallSheet, .body, Void

### Community 33 - "Decodable"
Cohesion: 0.29
Nodes (11): Decodable, BrewInfoPayload, FormulaInfo, IgnoredJSONValue, Installed, OutdatedItem, OutdatedPayload, RuntimeDependency (+3 more)

### Community 34 - "Equatable"
Cohesion: 0.25
Nodes (9): Equatable, CaskDependency, CaskInfo, FlexibleDependencyMap, FlexibleDependencyValue, FlexibleStringList, Decoder, CaskArtifacts (+1 more)

### Community 35 - "CatalogError"
Cohesion: 0.22
Nodes (8): LocalizedError, CatalogError, .errorDescription, httpStatus, noCachedCatalog, staleCacheFormat, Data, Int

### Community 36 - ".formulaPackages"
Cohesion: 0.39
Nodes (4): CatalogPackageMapper, Data, Int, popularity

### Community 37 - ".packages"
Cohesion: 0.40
Nodes (3): .columns, .split, BrewPackageMapper

### Community 41 - "AnalyticsItem"
Cohesion: 0.50
Nodes (4): AnalyticsItem, .installs, .name, AnalyticsPayload

## Knowledge Gaps
- **172 isolated node(s):** `PackageDescription`, `build-app.sh script`, `run-app.sh script`, `.body`, `.isPinned` (+167 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `PackageStore`, `PackageNodeID`, `LiveBrewService`, `PinnedStore`, `CatalogCategory`, `BrewPackage`, `PackageIconView`, `.sources`, `BrowseShelves.swift`, `View`, `BreweryCore`, `CategoryTileGrid`, `InstalledPackagesView`, `CatalogSearchResults`, `CodingKeys`, `BrowseView`, `CodingKeys`, `CodingKeys`, `CatalogPackage`, `BrewAction`, `BrowseView.swift`, `.fixture`, `InstallSheet`, `Decodable`, `Equatable`, `CatalogError`, `.formulaPackages`, `AnalyticsItem`?**
  _High betweenness centrality (0.502) - this node is a cross-community bridge._
- **Why does `CatalogPackage` connect `CatalogPackage` to `PackageStore`, `String`, `PackageNodeID`, `Equatable`, `.formulaPackages`, `PinnedStore`, `CatalogCategory`, `BreweryCoreTests`, `PackageIconView`, `BrowseShelves.swift`, `View`, `CategoryTileGrid`, `CatalogSearchResults`, `CatalogStore`, `BrowseView`, `Foundation`, `CodingKeys`, `BrowseView.swift`?**
  _High betweenness centrality (0.147) - this node is a cross-community bridge._
- **Why does `BrewPackage` connect `BrewPackage` to `PackageStore`, `String`, `PackageNodeID`, `Equatable`, `LiveBrewService`, `.packages`, `CatalogCategory`, `BreweryCoreTests`, `PackageIconView`, `View`, `InstalledCaskCard`, `InstalledPackagesView`, `CatalogSearchResults`, `CatalogStore`, `BrowseView`?**
  _High betweenness centrality (0.074) - this node is a cross-community bridge._
- **Are the 11 inferred relationships involving `CatalogPackage` (e.g. with `.body` and `.body`) actually correct?**
  _`CatalogPackage` has 11 INFERRED edges - model-reasoned connections that need verification._
- **Are the 5 inferred relationships involving `BrewPackage` (e.g. with `.body` and `.filteredPackages`) actually correct?**
  _`BrewPackage` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Are the 7 inferred relationships involving `PackageNodeID` (e.g. with `.inventory()` and `.refreshInventory()`) actually correct?**
  _`PackageNodeID` has 7 INFERRED edges - model-reasoned connections that need verification._
- **What connects `PackageDescription`, `build-app.sh script`, `run-app.sh script` to the rest of the system?**
  _172 weakly-connected nodes found - possible documentation gaps or missing edges._