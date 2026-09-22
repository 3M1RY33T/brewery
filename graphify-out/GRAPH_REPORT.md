# Graph Report - brewery  (2026-09-21)

## Corpus Check
- 44 files · ~228,353 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 731 nodes · 1746 edges · 38 communities (34 shown, 4 thin omitted)
- Extraction: 91% EXTRACTED · 9% INFERRED · 0% AMBIGUOUS · INFERRED: 165 edges (avg confidence: 0.83)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `d5394fc3`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- BrewJSON.swift
- String
- BrewDependencyGraph
- CatalogStore
- LiveBrewService
- BreweryCoreTests
- CatalogCategory
- BreweryCore
- PackageIconView
- .sources
- View
- PackageNodeID
- CatalogPackage
- README.md
- BrewPackage
- BrowseView.swift
- ContentView
- InstalledPackagesView
- Foundation
- Package.swift
- build-app.sh
- run-app.sh
- CodingKeys
- InstalledCaskCard
- BrowseShelves.swift
- CatalogSnapshot
- CodingKeys
- CodingKeys
- CatalogError
- BrewAction
- PinnedStore
- MockCatalogFetcher
- BrowseView
- Decodable
- Equatable
- Void
- .formulaPackages
- TileGridFramePreference

## God Nodes (most connected - your core abstractions)
1. `CatalogPackage` - 65 edges
2. `BreweryCoreTests` - 49 edges
3. `BrewPackage` - 48 edges
4. `PackageNodeID` - 44 edges
5. `PackageStore` - 40 edges
6. `BrewAction` - 36 edges
7. `CodingKeys` - 34 edges
8. `CatalogCategory` - 33 edges
9. `CatalogStore` - 33 edges
10. `PackageIconView` - 26 edges

## Surprising Connections (you probably didn't know these)
- `.visible` --references--> `CatalogSection`  [INFERRED]
  Sources/Brewery/BrowseShelves.swift → Sources/BreweryCore/CatalogPackage.swift
- `StubFileManager` --references--> `String`  [EXTRACTED]
  Tests/BreweryCoreTests/BreweryCoreTests.swift → Sources/BreweryCore/BrewDetector.swift
- `MockCatalogFetcher` --implements--> `CatalogFetching`  [EXTRACTED]
  Tests/BreweryCoreTests/BreweryCoreTests.swift → Sources/BreweryCore/CatalogStore.swift
- `BreweryApp` --calls--> `PackageStore`  [INFERRED]
  Sources/Brewery/BreweryApp.swift → Sources/BreweryCore/PackageStore.swift
- `BreweryApp` --calls--> `PinnedStore`  [INFERRED]
  Sources/Brewery/BreweryApp.swift → Sources/BreweryCore/PinnedStore.swift

## Import Cycles
- None detected.

## Communities (38 total, 4 thin omitted)

### Community 0 - "BrewJSON.swift"
Cohesion: 0.20
Nodes (8): .columns, BrewInfoPayload, BrewPackageMapper, FlexibleDependencyValue, IgnoredJSONValue, OutdatedItem, OutdatedPayload, Decoder

### Community 1 - "String"
Cohesion: 0.19
Nodes (11): CodingKey, String, .nilIfEmpty, DynamicCodingKey, Int, CaskAppArtifact, CaskAppArtifactEntry, CaskArtifactEntry (+3 more)

### Community 2 - "BrewDependencyGraph"
Cohesion: 0.11
Nodes (14): Hashable, KeyPath, BrewDependencyGraph, BrewInventory, DependencyEdge, .isDirectRelationship, DependencyRelationship, caskDeclared (+6 more)

### Community 3 - "CatalogStore"
Cohesion: 0.19
Nodes (7): CatalogStore, .isSearching, .searchResults, TimeInterval, URL, MockBrewService, URL

### Community 4 - "LiveBrewService"
Cohesion: 0.05
Nodes (36): FileManager, Int32, JSONDecoder, CommandLogView, .body, BrewDetectionReport, .isAvailable, BrewDetector (+28 more)

### Community 6 - "CatalogCategory"
Cohesion: 0.05
Nodes (40): CaseIterable, PackageFilter, browse, casks, diagnostics, formulae, .id, library (+32 more)

### Community 7 - "BreweryCore"
Cohesion: 0.07
Nodes (25): AnyObject, App, BreweryCore, Scene, BreweryApp, ConfirmationSheet, .body, InstallSheet (+17 more)

### Community 8 - "PackageIconView"
Cohesion: 0.07
Nodes (33): ImageIO, Never, Sendable, .body, IconError, unusable, NSImage, PackageIconLoader (+25 more)

### Community 9 - ".sources"
Cohesion: 0.16
Nodes (8): PackageIconResolver, PackageIconSource, appBundle, remote, Bool, FileManager, Set, URL

### Community 10 - "View"
Cohesion: 0.16
Nodes (20): .body, ChartRow, .body, .body, .body, InstallButton, .body, PinButton (+12 more)

### Community 11 - "PackageNodeID"
Cohesion: 0.17
Nodes (12): Codable, Comparable, Identifiable, PackageKind, cask, formula, .id, .title (+4 more)

### Community 12 - "CatalogPackage"
Cohesion: 0.22
Nodes (11): Encoder, CatalogShelf, .subtitle, CatalogPackage, CatalogSection, .id, .isEmpty, Date (+3 more)

### Community 13 - "README.md"
Cohesion: 0.17
Nodes (11): Browse the whole catalog, Build from source, Credits, Diagnostics, Features, Install, [Install Homebrew on macOS:](https://brew.sh/), Notes (+3 more)

### Community 14 - "BrewPackage"
Cohesion: 0.19
Nodes (14): InstalledCasksSheet, .body, .caskRow, DependencyNodeList, .body, PackageDetailView, .body, Void (+6 more)

### Community 15 - "BrowseView.swift"
Cohesion: 0.15
Nodes (20): .searchResults, CaskShelfRow, .body, CatalogCard, .body, CatalogPackageDetailView, .body, DetailPinButton (+12 more)

### Community 16 - "ContentView"
Cohesion: 0.11
Nodes (17): AppKit, Context, Gesture, NSEvent, NSTrackingArea, NSView, NSViewRepresentable, ContentView (+9 more)

### Community 17 - "InstalledPackagesView"
Cohesion: 0.18
Nodes (10): Accessory, Content, InstalledFormulaRow, InstalledPackagesView, .body, .casks, .emptyState, .formulae (+2 more)

### Community 18 - "Foundation"
Cohesion: 0.09
Nodes (14): Combine, Foundation, Array, CatalogInstallStatus, installed, notInstalled, .title, CatalogSearchResults (+6 more)

### Community 22 - "CodingKeys"
Cohesion: 0.07
Nodes (27): CodingKeys, artifacts, casks, caveats, currentVersion, declaredDirectly, dependencies, dependsOn (+19 more)

### Community 23 - "InstalledCaskCard"
Cohesion: 0.18
Nodes (13): CaskGridView, .body, .emptyState, InstalledCaskCard, .body, InstalledVersionLabel, .body, Bool (+5 more)

### Community 24 - "BrowseShelves.swift"
Cohesion: 0.15
Nodes (14): CategoryTileGrid, .canToggle, .collapsedCount, .columnCount, .grid, .visible, Color, HeroCard (+6 more)

### Community 25 - "CatalogSnapshot"
Cohesion: 0.29
Nodes (4): .header, CatalogSnapshot, .isCurrent, Bool

### Community 26 - "CodingKeys"
Cohesion: 0.20
Nodes (10): CodingKeys, appBundleName, dependencies, description, displayName, homepage, kind, name (+2 more)

### Community 27 - "CodingKeys"
Cohesion: 0.15
Nodes (13): CodingKeys, artifacts, dependencies, dependsOn, desc, fullName, fullToken, homepage (+5 more)

### Community 28 - "CatalogError"
Cohesion: 0.16
Nodes (10): LocalizedError, CatalogError, .errorDescription, httpStatus, noCachedCatalog, staleCacheFormat, CatalogFetching, Data (+2 more)

### Community 29 - "BrewAction"
Cohesion: 0.11
Nodes (15): .contentPane, Void, BrewAction, .arguments, cleanup, .commandDisplay, .id, install (+7 more)

### Community 30 - "PinnedStore"
Cohesion: 0.19
Nodes (10): ObservableObject, .body, .body, PinnedStore, .count, .isEmpty, Bool, Int (+2 more)

### Community 31 - "MockCatalogFetcher"
Cohesion: 0.22
Nodes (8): CoreGraphics, Error, MockCatalogFetcher, NotStubbed, Data, Int, URL, XCTest

### Community 32 - "BrowseView"
Cohesion: 0.26
Nodes (7): ScrollViewProxy, ShelfHeader, .body, BrowseView, .body, .pinnedResults, .body

### Community 33 - "Decodable"
Cohesion: 0.27
Nodes (11): Decodable, FormulaInfo, Installed, RuntimeDependency, .packageName, Bool, Versions, AnalyticsItem (+3 more)

### Community 34 - "Equatable"
Cohesion: 0.39
Nodes (8): Equatable, CaskDependency, CaskInfo, FlexibleDependencyMap, FlexibleStringList, BrewDiagnostics, CaskArtifacts, CaskCatalogItem

### Community 35 - "Void"
Cohesion: 0.36
Nodes (9): CompactCell, CompactIconGrid, .body, SpotlightCard, SpotlightShelf, .body, Double, Void (+1 more)

### Community 36 - ".formulaPackages"
Cohesion: 0.46
Nodes (4): CatalogPackageMapper, Data, Int, popularity

### Community 37 - "TileGridFramePreference"
Cohesion: 0.67
Nodes (3): PreferenceKey, CGRect, TileGridFramePreference

## Knowledge Gaps
- **175 isolated node(s):** `PackageDescription`, `build-app.sh script`, `run-app.sh script`, `.body`, `.isPinned` (+170 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `BrewJSON.swift`, `BrewDependencyGraph`, `LiveBrewService`, `BreweryCoreTests`, `CatalogCategory`, `BreweryCore`, `PackageIconView`, `.sources`, `View`, `PackageNodeID`, `CatalogPackage`, `BrewPackage`, `BrowseView.swift`, `InstalledPackagesView`, `Foundation`, `CodingKeys`, `BrowseShelves.swift`, `CodingKeys`, `CodingKeys`, `CatalogError`, `BrewAction`, `PinnedStore`, `BrowseView`, `Decodable`, `Equatable`, `.formulaPackages`?**
  _High betweenness centrality (0.506) - this node is a cross-community bridge._
- **Why does `CatalogPackage` connect `CatalogPackage` to `BrowseView`, `String`, `Equatable`, `Void`, `.formulaPackages`, `BreweryCoreTests`, `CatalogStore`, `PackageIconView`, `View`, `PackageNodeID`, `BrowseView.swift`, `ContentView`, `Foundation`, `BrowseShelves.swift`, `CatalogSnapshot`, `CodingKeys`?**
  _High betweenness centrality (0.131) - this node is a cross-community bridge._
- **Why does `BrewPackage` connect `BrewPackage` to `BrowseView`, `BrewJSON.swift`, `BrewDependencyGraph`, `Equatable`, `String`, `LiveBrewService`, `CatalogStore`, `BreweryCore`, `PackageIconView`, `BreweryCoreTests`, `PackageNodeID`, `InstalledPackagesView`, `Foundation`, `InstalledCaskCard`, `CatalogSnapshot`?**
  _High betweenness centrality (0.074) - this node is a cross-community bridge._
- **Are the 12 inferred relationships involving `CatalogPackage` (e.g. with `.body` and `.body`) actually correct?**
  _`CatalogPackage` has 12 INFERRED edges - model-reasoned connections that need verification._
- **Are the 5 inferred relationships involving `BrewPackage` (e.g. with `.body` and `.filteredPackages`) actually correct?**
  _`BrewPackage` has 5 INFERRED edges - model-reasoned connections that need verification._
- **What connects `PackageDescription`, `build-app.sh script`, `run-app.sh script` to the rest of the system?**
  _175 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `BrewDependencyGraph` be split into smaller, more focused modules?**
  _Cohesion score 0.11491935483870967 - nodes in this community are weakly interconnected._