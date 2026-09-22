# Graph Report - brewery  (2026-09-21)

## Corpus Check
- 42 files · ~225,982 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 679 nodes · 1593 edges · 36 communities (33 shown, 3 thin omitted)
- Extraction: 92% EXTRACTED · 8% INFERRED · 0% AMBIGUOUS · INFERRED: 134 edges (avg confidence: 0.83)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `7411b0e6`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- CatalogSearch
- String
- PackageNodeID
- CatalogStore
- LiveBrewService
- BrowseView.swift
- CatalogCategory
- BreweryCore
- IconDiskCache
- .sources
- BrowseShelves.swift
- PackageStore
- CatalogPackage
- README.md
- View
- BreweryCoreTests
- PackageIconView
- TopChartsShelf
- CatalogError
- Package.swift
- build-app.sh
- run-app.sh
- CodingKeys
- InstalledCaskCard
- BrowseView
- .selectionRing
- CodingKeys
- .fixture
- MockBrewService
- BrewAction
- ContentView
- CommandLogEntry
- .contentPane
- .formulaPackages
- .body
- BrewPackage

## God Nodes (most connected - your core abstractions)
1. `CatalogPackage` - 61 edges
2. `PackageNodeID` - 44 edges
3. `BreweryCoreTests` - 44 edges
4. `BrewPackage` - 39 edges
5. `PackageStore` - 37 edges
6. `CodingKeys` - 34 edges
7. `CatalogCategory` - 33 edges
8. `CatalogStore` - 30 edges
9. `BrewAction` - 28 edges
10. `PackageIconView` - 25 edges

## Surprising Connections (you probably didn't know these)
- `.visible` --references--> `CatalogSection`  [INFERRED]
  Sources/Brewery/BrowseShelves.swift → Sources/BreweryCore/CatalogPackage.swift
- `.body` --calls--> `PackageIconView`  [INFERRED]
  Sources/Brewery/BrowseView.swift → Sources/Brewery/PackageIconView.swift
- `.body` --calls--> `PackageIconView`  [INFERRED]
  Sources/Brewery/BrowseView.swift → Sources/Brewery/PackageIconView.swift
- `.body` --calls--> `PackageIconView`  [INFERRED]
  Sources/Brewery/CaskGridView.swift → Sources/Brewery/PackageIconView.swift
- `MockCatalogFetcher` --implements--> `CatalogFetching`  [EXTRACTED]
  Tests/BreweryCoreTests/BreweryCoreTests.swift → Sources/BreweryCore/CatalogStore.swift

## Import Cycles
- None detected.

## Communities (36 total, 3 thin omitted)

### Community 0 - "CatalogSearch"
Cohesion: 0.29
Nodes (3): CatalogSearch, Bool, Int

### Community 1 - "String"
Cohesion: 0.05
Nodes (58): CodingKey, Decodable, Equatable, FileManager, BrewDetectionReport, .isAvailable, BrewDetector, String (+50 more)

### Community 2 - "PackageNodeID"
Cohesion: 0.12
Nodes (18): Codable, Comparable, Hashable, KeyPath, .split, BrewDependencyGraph, BrewInventory, DependencyEdge (+10 more)

### Community 3 - "CatalogStore"
Cohesion: 0.24
Nodes (7): ObservableObject, CatalogStore, .isSearching, .searchResults, Bool, TimeInterval, URL

### Community 4 - "LiveBrewService"
Cohesion: 0.11
Nodes (19): Int32, JSONDecoder, BrewActionDisplay, BrewServiceError, brewNotFound, commandFailed, decodingFailed, .errorDescription (+11 more)

### Community 5 - "BrowseView.swift"
Cohesion: 0.17
Nodes (18): .searchResults, CaskShelfRow, .body, CatalogCard, .body, CatalogShelf, .subtitle, FormulaRow (+10 more)

### Community 6 - "CatalogCategory"
Cohesion: 0.07
Nodes (30): CatalogCategory, ai, .assignable, communication, data, design, developerTools, featured (+22 more)

### Community 7 - "BreweryCore"
Cohesion: 0.09
Nodes (17): AppKit, BreweryCore, Context, CoreGraphics, ImageIO, NSEvent, NSTrackingArea, NSView (+9 more)

### Community 8 - "IconDiskCache"
Cohesion: 0.09
Nodes (22): Never, Sendable, NSImage, PackageIconLoader, .body, ResolvedIcon, appBundle, downloaded (+14 more)

### Community 9 - ".sources"
Cohesion: 0.13
Nodes (8): PackageIconResolver, PackageIconSource, appBundle, remote, Bool, FileManager, Set, URL

### Community 10 - "BrowseShelves.swift"
Cohesion: 0.16
Nodes (21): CategoryTileGrid, .body, .canToggle, .collapsedCount, .columnCount, .visible, ChartRow, CompactCell (+13 more)

### Community 11 - "PackageStore"
Cohesion: 0.35
Nodes (5): AnyObject, BrewServicing, PackageStore, Sendable, Void

### Community 12 - "CatalogPackage"
Cohesion: 0.14
Nodes (19): Encoder, Identifiable, CatalogInstallStatus, installed, notInstalled, .title, CatalogPackage, CatalogSearchResults (+11 more)

### Community 13 - "README.md"
Cohesion: 0.17
Nodes (11): Browse the whole catalog, Build from source, Credits, Diagnostics, Features, Install, [Install Homebrew on macOS:](https://brew.sh/), Notes (+3 more)

### Community 14 - "View"
Cohesion: 0.23
Nodes (12): View, CatalogPackageDetailView, .body, DependencyNodeList, .body, DetailBlock, .body, DetailRow (+4 more)

### Community 15 - "BreweryCoreTests"
Cohesion: 0.18
Nodes (4): Set, BreweryCoreTests, Int, XCTestCase

### Community 16 - "PackageIconView"
Cohesion: 0.13
Nodes (19): .grid, .body, Color, .body, HeroCard, .body, .gradientStops, .body (+11 more)

### Community 17 - "TopChartsShelf"
Cohesion: 0.22
Nodes (9): ShelfHeader, .body, Int, TopChartsShelf, .body, .canShowLess, .canShowMore, .longest (+1 more)

### Community 18 - "CatalogError"
Cohesion: 0.15
Nodes (11): Combine, LocalizedError, CatalogError, .errorDescription, httpStatus, noCachedCatalog, staleCacheFormat, CatalogFetching (+3 more)

### Community 22 - "CodingKeys"
Cohesion: 0.07
Nodes (27): CodingKeys, artifacts, casks, caveats, currentVersion, declaredDirectly, dependencies, dependsOn (+19 more)

### Community 23 - "InstalledCaskCard"
Cohesion: 0.19
Nodes (10): CaskGridView, .body, .emptyState, InstalledCaskCard, .body, .version, Bool, Int (+2 more)

### Community 24 - "BrowseView"
Cohesion: 0.46
Nodes (3): ScrollViewProxy, BrowseView, .body

### Community 25 - ".selectionRing"
Cohesion: 0.50
Nodes (3): PreferenceKey, CGFloat, WidthPreference

### Community 26 - "CodingKeys"
Cohesion: 0.20
Nodes (10): CodingKeys, appBundleName, dependencies, description, displayName, homepage, kind, name (+2 more)

### Community 27 - ".fixture"
Cohesion: 0.29
Nodes (7): Error, IconError, unusable, MockCatalogFetcher, NotStubbed, Data, URL

### Community 28 - "MockBrewService"
Cohesion: 0.20
Nodes (5): BrewDiagnostics, MockBrewService, Bool, Sendable, URL

### Community 29 - "BrewAction"
Cohesion: 0.06
Nodes (33): CaseIterable, Foundation, ConfirmationSheet, .body, InstallSheet, .body, Void, BrewAction (+25 more)

### Community 30 - "ContentView"
Cohesion: 0.25
Nodes (9): Gesture, ContentView, .clampedDetailPaneWidth, .mainInterface, .packageSearchHeader, CGRect, Double, SidebarView (+1 more)

### Community 31 - "CommandLogEntry"
Cohesion: 0.28
Nodes (7): CommandLogView, .body, CommandLogEntry, Stream, status, stderr, stdout

### Community 32 - ".contentPane"
Cohesion: 0.25
Nodes (6): .contentPane, DiagnosticsBlock, .body, DiagnosticsView, .body, PackageTableView

### Community 33 - ".formulaPackages"
Cohesion: 0.39
Nodes (4): CatalogPackageMapper, Data, Int, popularity

### Community 34 - ".body"
Cohesion: 0.25
Nodes (7): App, Scene, BreweryApp, .body, .header, .body, Task

### Community 35 - "BrewPackage"
Cohesion: 0.32
Nodes (5): BrewPackage, Bool, URL, .filteredPackages, .selectedPackage

## Knowledge Gaps
- **168 isolated node(s):** `PackageDescription`, `build-app.sh script`, `run-app.sh script`, `.body`, `.body` (+163 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `CatalogSearch`, `PackageNodeID`, `LiveBrewService`, `BrowseView.swift`, `CatalogCategory`, `IconDiskCache`, `.sources`, `BrowseShelves.swift`, `PackageStore`, `CatalogPackage`, `View`, `BreweryCoreTests`, `PackageIconView`, `TopChartsShelf`, `CatalogError`, `CodingKeys`, `BrowseView`, `CodingKeys`, `.fixture`, `MockBrewService`, `BrewAction`, `ContentView`, `CommandLogEntry`, `.contentPane`, `.formulaPackages`, `BrewPackage`?**
  _High betweenness centrality (0.512) - this node is a cross-community bridge._
- **Why does `CatalogPackage` connect `CatalogPackage` to `CatalogSearch`, `.formulaPackages`, `PackageNodeID`, `String`, `CatalogStore`, `BrowseView.swift`, `BrowseShelves.swift`, `View`, `BreweryCoreTests`, `PackageIconView`, `TopChartsShelf`, `BrowseView`, `CodingKeys`, `BrewAction`, `ContentView`?**
  _High betweenness centrality (0.137) - this node is a cross-community bridge._
- **Why does `CodingKeys` connect `CodingKeys` to `String`?**
  _High betweenness centrality (0.075) - this node is a cross-community bridge._
- **Are the 11 inferred relationships involving `CatalogPackage` (e.g. with `.body` and `.body`) actually correct?**
  _`CatalogPackage` has 11 INFERRED edges - model-reasoned connections that need verification._
- **Are the 7 inferred relationships involving `PackageNodeID` (e.g. with `.inventory()` and `.refreshInventory()`) actually correct?**
  _`PackageNodeID` has 7 INFERRED edges - model-reasoned connections that need verification._
- **What connects `PackageDescription`, `build-app.sh script`, `run-app.sh script` to the rest of the system?**
  _168 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `String` be split into smaller, more focused modules?**
  _Cohesion score 0.050774526678141134 - nodes in this community are weakly interconnected._