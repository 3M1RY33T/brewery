# Graph Report - brewery  (2026-09-21)

## Corpus Check
- 44 files · ~228,269 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 729 nodes · 1741 edges · 46 communities (39 shown, 7 thin omitted)
- Extraction: 91% EXTRACTED · 9% INFERRED · 0% AMBIGUOUS · INFERRED: 165 edges (avg confidence: 0.83)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `abd33c25`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- .inventory
- DynamicCodingKey
- PackageNodeID
- CatalogStore
- LiveBrewService
- BreweryCoreTests
- CatalogCategory
- BreweryCore
- String
- .sources
- View
- PackageFilter
- CatalogSection
- README.md
- BrewPackage
- CatalogPackage
- CursorTrackingView
- InstalledPackagesView
- .sections
- Package.swift
- build-app.sh
- run-app.sh
- CodingKeys
- InstalledCaskCard
- CategoryTileGrid
- CatalogSnapshot
- CodingKeys
- CodingKeys
- CatalogError
- BrewAction
- PinnedStore
- MockCatalogFetcher
- BrowseView
- FormulaInfo
- Equatable
- PackageIconView
- .formulaPackages
- CGFloat
- ContentView
- Foundation
- .body
- AnalyticsItem
- CatalogShelfStyle
- SidebarView
- DetailBlock
- DetailRow

## God Nodes (most connected - your core abstractions)
1. `CatalogPackage` - 65 edges
2. `BreweryCoreTests` - 49 edges
3. `BrewPackage` - 48 edges
4. `PackageNodeID` - 44 edges
5. `PackageStore` - 40 edges
6. `BrewAction` - 35 edges
7. `CodingKeys` - 34 edges
8. `CatalogCategory` - 33 edges
9. `CatalogStore` - 33 edges
10. `PackageIconView` - 26 edges

## Surprising Connections (you probably didn't know these)
- `.visible` --references--> `CatalogSection`  [INFERRED]
  Sources/Brewery/BrowseShelves.swift → Sources/BreweryCore/CatalogPackage.swift
- `MockCatalogFetcher` --implements--> `CatalogFetching`  [EXTRACTED]
  Tests/BreweryCoreTests/BreweryCoreTests.swift → Sources/BreweryCore/CatalogStore.swift
- `BreweryApp` --calls--> `PackageStore`  [INFERRED]
  Sources/Brewery/BreweryApp.swift → Sources/BreweryCore/PackageStore.swift
- `.body` --calls--> `ContentView`  [INFERRED]
  Sources/Brewery/BreweryApp.swift → Sources/Brewery/ContentView.swift
- `.body` --calls--> `PinButton`  [INFERRED]
  Sources/Brewery/BrowseView.swift → Sources/Brewery/BrowseShelves.swift

## Import Cycles
- None detected.

## Communities (46 total, 7 thin omitted)

### Community 0 - ".inventory"
Cohesion: 0.22
Nodes (6): .columns, BrewInfoPayload, BrewPackageMapper, OutdatedItem, OutdatedPayload, Decoder

### Community 1 - "DynamicCodingKey"
Cohesion: 0.20
Nodes (7): CodingKey, DynamicCodingKey, Int, CaskAppArtifact, CaskAppArtifactEntry, CaskArtifactEntry, Decoder

### Community 2 - "PackageNodeID"
Cohesion: 0.14
Nodes (17): Codable, Comparable, Hashable, KeyPath, BrewDependencyGraph, BrewInventory, DependencyEdge, .isDirectRelationship (+9 more)

### Community 3 - "CatalogStore"
Cohesion: 0.23
Nodes (7): CatalogStore, .isSearching, .searchResults, TimeInterval, URL, MockBrewService, URL

### Community 4 - "LiveBrewService"
Cohesion: 0.06
Nodes (35): AnyObject, Int32, JSONDecoder, LocalizedError, CommandLogView, .body, DiagnosticsBlock, .body (+27 more)

### Community 5 - "BreweryCoreTests"
Cohesion: 0.18
Nodes (3): BreweryCoreTests, Int, XCTestCase

### Community 6 - "CatalogCategory"
Cohesion: 0.08
Nodes (26): CatalogCategory, ai, .assignable, communication, data, design, developerTools, featured (+18 more)

### Community 7 - "BreweryCore"
Cohesion: 0.24
Nodes (5): AppKit, BreweryCore, MissingHomebrewView, .body, SwiftUI

### Community 8 - "String"
Cohesion: 0.06
Nodes (35): FileManager, ImageIO, Never, Sendable, .body, NSImage, PackageIconLoader, ResolvedIcon (+27 more)

### Community 9 - ".sources"
Cohesion: 0.16
Nodes (8): PackageIconResolver, PackageIconSource, appBundle, remote, Bool, FileManager, Set, URL

### Community 10 - "View"
Cohesion: 0.17
Nodes (26): .grid, ChartRow, .body, Color, CompactCell, .body, CompactIconGrid, .body (+18 more)

### Community 11 - "PackageFilter"
Cohesion: 0.17
Nodes (10): CaseIterable, Array, PackageFilter, browse, casks, diagnostics, formulae, .id (+2 more)

### Community 12 - "CatalogSection"
Cohesion: 0.16
Nodes (12): CatalogInstallStatus, installed, notInstalled, .title, CatalogSection, .id, .isEmpty, Bool (+4 more)

### Community 13 - "README.md"
Cohesion: 0.17
Nodes (11): Browse the whole catalog, Build from source, Credits, Diagnostics, Features, Install, [Install Homebrew on macOS:](https://brew.sh/), Notes (+3 more)

### Community 14 - "BrewPackage"
Cohesion: 0.16
Nodes (14): .contentPane, DiagnosticsView, InstalledCasksSheet, DependencyNodeList, .body, PackageDetailView, .body, Void (+6 more)

### Community 15 - "CatalogPackage"
Cohesion: 0.17
Nodes (22): Encoder, .searchResults, CaskShelfRow, .body, CatalogCard, CatalogPackageDetailView, .body, CatalogShelf (+14 more)

### Community 16 - "CursorTrackingView"
Cohesion: 0.21
Nodes (7): Context, NSEvent, NSTrackingArea, NSView, NSViewRepresentable, CursorTrackingView, ResizeCursorArea

### Community 17 - "InstalledPackagesView"
Cohesion: 0.13
Nodes (17): Accessory, Content, .body, InstalledVersionLabel, .body, InstalledFormulaRow, .body, InstalledPackagesView (+9 more)

### Community 18 - ".sections"
Cohesion: 0.14
Nodes (6): CatalogSearchResults, .isEmpty, CatalogSearch, Bool, Int, Set

### Community 22 - "CodingKeys"
Cohesion: 0.07
Nodes (27): CodingKeys, artifacts, casks, caveats, currentVersion, declaredDirectly, dependencies, dependsOn (+19 more)

### Community 23 - "InstalledCaskCard"
Cohesion: 0.22
Nodes (11): CaskGridView, .body, .emptyState, InstalledCaskCard, Bool, Int, Void, .body (+3 more)

### Community 24 - "CategoryTileGrid"
Cohesion: 0.15
Nodes (14): CategoryTileGrid, .body, .canToggle, .collapsedCount, .columnCount, .visible, ShowMoreButton, .body (+6 more)

### Community 25 - "CatalogSnapshot"
Cohesion: 0.21
Nodes (4): .header, CatalogSnapshot, .isCurrent, Bool

### Community 26 - "CodingKeys"
Cohesion: 0.20
Nodes (10): CodingKeys, appBundleName, dependencies, description, displayName, homepage, kind, name (+2 more)

### Community 27 - "CodingKeys"
Cohesion: 0.15
Nodes (13): CodingKeys, artifacts, dependencies, dependsOn, desc, fullName, fullToken, homepage (+5 more)

### Community 28 - "CatalogError"
Cohesion: 0.18
Nodes (9): CatalogError, .errorDescription, httpStatus, noCachedCatalog, staleCacheFormat, CatalogFetching, Data, Int (+1 more)

### Community 29 - "BrewAction"
Cohesion: 0.08
Nodes (20): Identifiable, BrewAction, .arguments, cleanup, .commandDisplay, .id, install, .isMutating (+12 more)

### Community 30 - "PinnedStore"
Cohesion: 0.13
Nodes (13): App, ObservableObject, Scene, BreweryApp, .body, .body, PinnedStore, .count (+5 more)

### Community 31 - "MockCatalogFetcher"
Cohesion: 0.24
Nodes (9): CoreGraphics, Error, IconError, unusable, MockCatalogFetcher, NotStubbed, Data, URL (+1 more)

### Community 32 - "BrowseView"
Cohesion: 0.29
Nodes (6): ScrollViewProxy, ShelfHeader, .body, BrowseView, .body, .pinnedResults

### Community 33 - "FormulaInfo"
Cohesion: 0.47
Nodes (6): FormulaInfo, Installed, RuntimeDependency, .packageName, Bool, Versions

### Community 34 - "Equatable"
Cohesion: 0.41
Nodes (10): Decodable, Equatable, CaskDependency, CaskInfo, FlexibleDependencyMap, FlexibleDependencyValue, FlexibleStringList, IgnoredJSONValue (+2 more)

### Community 35 - "PackageIconView"
Cohesion: 0.22
Nodes (10): .body, .body, PackageIconView, .body, .glyph, .glyphColor, .isFont, Bool (+2 more)

### Community 36 - ".formulaPackages"
Cohesion: 0.46
Nodes (4): CatalogPackageMapper, Data, Int, popularity

### Community 37 - "CGFloat"
Cohesion: 0.32
Nodes (5): PreferenceKey, CGFloat, WidthPreference, CGRect, TileGridFramePreference

### Community 38 - "ContentView"
Cohesion: 0.27
Nodes (9): Gesture, ContentView, .clampedDetailPaneWidth, .mainInterface, .packageSearchHeader, DetailPaneResizeHandle, .body, CGRect (+1 more)

### Community 40 - ".body"
Cohesion: 0.32
Nodes (6): ConfirmationSheet, .body, InstallSheet, .body, Void, .body

### Community 41 - "AnalyticsItem"
Cohesion: 0.33
Nodes (6): AnalyticsItem, .installs, .name, AnalyticsPayload, FormulaCatalogItem, Versions

### Community 42 - "CatalogShelfStyle"
Cohesion: 0.40
Nodes (4): CatalogShelfStyle, compactGrid, showcase, spotlight

## Knowledge Gaps
- **174 isolated node(s):** `PackageDescription`, `build-app.sh script`, `run-app.sh script`, `.body`, `.isPinned` (+169 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `.inventory`, `DynamicCodingKey`, `PackageNodeID`, `LiveBrewService`, `BreweryCoreTests`, `CatalogCategory`, `.sources`, `PackageFilter`, `CatalogSection`, `BrewPackage`, `CatalogPackage`, `InstalledPackagesView`, `.sections`, `CodingKeys`, `CategoryTileGrid`, `CodingKeys`, `CodingKeys`, `CatalogError`, `BrewAction`, `PinnedStore`, `BrowseView`, `FormulaInfo`, `Equatable`, `PackageIconView`, `.formulaPackages`, `.body`, `AnalyticsItem`, `SidebarView`, `DetailBlock`, `DetailRow`?**
  _High betweenness centrality (0.506) - this node is a cross-community bridge._
- **Why does `CatalogPackage` connect `CatalogPackage` to `BrowseView`, `PackageNodeID`, `PackageIconView`, `.formulaPackages`, `Equatable`, `ContentView`, `Foundation`, `String`, `CatalogStore`, `View`, `CatalogSection`, `.sections`, `CategoryTileGrid`, `CatalogSnapshot`, `CodingKeys`, `BrewAction`, `PinnedStore`?**
  _High betweenness centrality (0.131) - this node is a cross-community bridge._
- **Why does `BrewPackage` connect `BrewPackage` to `BrowseView`, `.inventory`, `PackageNodeID`, `PackageIconView`, `Equatable`, `LiveBrewService`, `CatalogStore`, `BreweryCoreTests`, `String`, `.body`, `PackageFilter`, `InstalledPackagesView`, `InstalledCaskCard`, `CatalogSnapshot`, `BrewAction`?**
  _High betweenness centrality (0.074) - this node is a cross-community bridge._
- **Are the 12 inferred relationships involving `CatalogPackage` (e.g. with `.body` and `.body`) actually correct?**
  _`CatalogPackage` has 12 INFERRED edges - model-reasoned connections that need verification._
- **Are the 5 inferred relationships involving `BrewPackage` (e.g. with `.body` and `.filteredPackages`) actually correct?**
  _`BrewPackage` has 5 INFERRED edges - model-reasoned connections that need verification._
- **What connects `PackageDescription`, `build-app.sh script`, `run-app.sh script` to the rest of the system?**
  _174 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `PackageNodeID` be split into smaller, more focused modules?**
  _Cohesion score 0.13903743315508021 - nodes in this community are weakly interconnected._