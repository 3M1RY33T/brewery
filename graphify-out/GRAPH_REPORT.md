# Graph Report - brewery  (2026-09-21)

## Corpus Check
- 42 files · ~224,315 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 656 nodes · 1534 edges · 30 communities (27 shown, 3 thin omitted)
- Extraction: 91% EXTRACTED · 9% INFERRED · 0% AMBIGUOUS · INFERRED: 131 edges (avg confidence: 0.83)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `bc71cec1`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- CatalogPackage
- String
- PackageNodeID
- CatalogStore
- LiveBrewService
- BrowseView
- CatalogCategory
- CursorTrackingView
- PackageIconView
- BreweryCoreTests
- BrowseShelves.swift
- BrewServicing
- BreweryCore
- README.md
- View
- Equatable
- BrewPackage
- InstalledCaskCard
- CodingKeys
- Package.swift
- build-app.sh
- run-app.sh
- CodingKeys
- Decodable
- ContentView
- CommandLogEntry
- CodingKeys
- .body
- BrewAction
- AnalyticsItem

## God Nodes (most connected - your core abstractions)
1. `CatalogPackage` - 63 edges
2. `PackageNodeID` - 43 edges
3. `BrewPackage` - 39 edges
4. `BreweryCoreTests` - 39 edges
5. `PackageStore` - 36 edges
6. `CodingKeys` - 34 edges
7. `CatalogCategory` - 33 edges
8. `CatalogStore` - 29 edges
9. `BrewAction` - 28 edges
10. `PackageKind` - 24 edges

## Surprising Connections (you probably didn't know these)
- `.visible` --references--> `CatalogSection`  [INFERRED]
  Sources/Brewery/BrowseShelves.swift → Sources/BreweryCore/CatalogPackage.swift
- `.body` --calls--> `PackageIconView`  [INFERRED]
  Sources/Brewery/BrowseView.swift → Sources/Brewery/PackageIconView.swift
- `.body` --calls--> `PackageIconView`  [INFERRED]
  Sources/Brewery/BrowseView.swift → Sources/Brewery/PackageIconView.swift
- `.body` --calls--> `PackageIconView`  [INFERRED]
  Sources/Brewery/CaskGridView.swift → Sources/Brewery/PackageIconView.swift
- `StubFileManager` --references--> `String`  [EXTRACTED]
  Tests/BreweryCoreTests/BreweryCoreTests.swift → Sources/BreweryCore/BrewDetector.swift

## Import Cycles
- None detected.

## Communities (30 total, 3 thin omitted)

### Community 0 - "CatalogPackage"
Cohesion: 0.07
Nodes (28): Encoder, Identifiable, CatalogPackageDetailView, .body, CatalogPackageMapper, Data, Int, CatalogInstallStatus (+20 more)

### Community 1 - "String"
Cohesion: 0.19
Nodes (11): CodingKey, String, .nilIfEmpty, DynamicCodingKey, Int, CaskAppArtifact, CaskAppArtifactEntry, CaskArtifactEntry (+3 more)

### Community 2 - "PackageNodeID"
Cohesion: 0.12
Nodes (18): Codable, Comparable, Hashable, KeyPath, BrewDependencyGraph, BrewInventory, DependencyEdge, .isDirectRelationship (+10 more)

### Community 3 - "CatalogStore"
Cohesion: 0.08
Nodes (28): Combine, Error, Foundation, ObservableObject, IconError, unusable, CatalogSnapshot, .isCurrent (+20 more)

### Community 4 - "LiveBrewService"
Cohesion: 0.05
Nodes (34): FileManager, Int32, JSONDecoder, LocalizedError, BrewDetectionReport, .isAvailable, BrewDetector, Bool (+26 more)

### Community 5 - "BrowseView"
Cohesion: 0.13
Nodes (23): ScrollViewProxy, ShelfHeader, .body, BrowseView, .body, .searchResults, CaskShelfRow, .body (+15 more)

### Community 6 - "CatalogCategory"
Cohesion: 0.05
Nodes (41): CaseIterable, PackageFilter, all, browse, casks, diagnostics, formulae, .id (+33 more)

### Community 7 - "CursorTrackingView"
Cohesion: 0.16
Nodes (10): AppKit, Context, NSEvent, NSTrackingArea, NSView, NSViewRepresentable, CursorTrackingView, DetailPaneResizeHandle (+2 more)

### Community 8 - "PackageIconView"
Cohesion: 0.09
Nodes (24): ImageIO, Never, NSImage, Sendable, PackageIconLoader, PackageIconView, .body, ResolvedIcon (+16 more)

### Community 9 - "BreweryCoreTests"
Cohesion: 0.17
Nodes (8): PackageIconResolver, PackageIconSource, appBundle, remote, FileManager, URL, BreweryCoreTests, XCTestCase

### Community 10 - "BrowseShelves.swift"
Cohesion: 0.08
Nodes (40): PreferenceKey, CategoryTileGrid, .body, .canToggle, .collapsedCount, .columnCount, .grid, .visible (+32 more)

### Community 11 - "BrewServicing"
Cohesion: 0.17
Nodes (10): AnyObject, .body, .header, DiagnosticsBlock, .body, .body, BrewServicing, Sendable (+2 more)

### Community 12 - "BreweryCore"
Cohesion: 0.14
Nodes (12): App, BreweryCore, CoreGraphics, Scene, BreweryApp, .contentPane, DiagnosticsView, MissingHomebrewView (+4 more)

### Community 13 - "README.md"
Cohesion: 0.17
Nodes (11): Browse the whole catalog, Build from source, Credits, Diagnostics, Features, Install, [Install Homebrew on macOS:](https://brew.sh/), Notes (+3 more)

### Community 14 - "View"
Cohesion: 0.27
Nodes (10): DependencyNodeList, .body, DetailBlock, .body, DetailRow, .body, PackageDetailView, .body (+2 more)

### Community 15 - "Equatable"
Cohesion: 0.25
Nodes (9): Equatable, CaskDependency, CaskInfo, FlexibleDependencyMap, FlexibleDependencyValue, FlexibleStringList, Decoder, CaskArtifacts (+1 more)

### Community 16 - "BrewPackage"
Cohesion: 0.26
Nodes (7): .body, BrewPackage, Bool, URL, PackageStore, .filteredPackages, .selectedPackage

### Community 17 - "InstalledCaskCard"
Cohesion: 0.24
Nodes (9): CaskGridView, .body, .emptyState, InstalledCaskCard, .body, .version, Bool, Int (+1 more)

### Community 18 - "CodingKeys"
Cohesion: 0.15
Nodes (13): CodingKeys, artifacts, dependencies, dependsOn, desc, fullName, fullToken, homepage (+5 more)

### Community 22 - "CodingKeys"
Cohesion: 0.07
Nodes (27): CodingKeys, artifacts, casks, caveats, currentVersion, declaredDirectly, dependencies, dependsOn (+19 more)

### Community 23 - "Decodable"
Cohesion: 0.29
Nodes (11): Decodable, BrewInfoPayload, FormulaInfo, IgnoredJSONValue, Installed, OutdatedItem, OutdatedPayload, RuntimeDependency (+3 more)

### Community 24 - "ContentView"
Cohesion: 0.19
Nodes (10): CGRect, Gesture, ContentView, .clampedDetailPaneWidth, .mainInterface, .packageSearchHeader, Double, SidebarView (+2 more)

### Community 25 - "CommandLogEntry"
Cohesion: 0.28
Nodes (7): CommandLogView, .body, CommandLogEntry, Stream, status, stderr, stdout

### Community 26 - "CodingKeys"
Cohesion: 0.20
Nodes (10): CodingKeys, appBundleName, dependencies, description, displayName, homepage, kind, name (+2 more)

### Community 28 - ".body"
Cohesion: 0.32
Nodes (6): ConfirmationSheet, .body, InstallSheet, .body, Void, .body

### Community 29 - "BrewAction"
Cohesion: 0.11
Nodes (17): BrewAction, .arguments, cleanup, .commandDisplay, .id, install, .isMutating, .title (+9 more)

### Community 30 - "AnalyticsItem"
Cohesion: 0.50
Nodes (4): AnalyticsItem, .installs, .name, AnalyticsPayload

## Knowledge Gaps
- **166 isolated node(s):** `PackageDescription`, `build-app.sh script`, `run-app.sh script`, `.body`, `.body` (+161 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `CatalogPackage`, `PackageNodeID`, `CatalogStore`, `LiveBrewService`, `BrowseView`, `CatalogCategory`, `PackageIconView`, `BreweryCoreTests`, `BrowseShelves.swift`, `BrewServicing`, `View`, `Equatable`, `BrewPackage`, `CodingKeys`, `CodingKeys`, `Decodable`, `ContentView`, `CommandLogEntry`, `CodingKeys`, `.body`, `BrewAction`, `AnalyticsItem`?**
  _High betweenness centrality (0.510) - this node is a cross-community bridge._
- **Why does `CatalogPackage` connect `CatalogPackage` to `String`, `PackageNodeID`, `CatalogStore`, `BrowseView`, `PackageIconView`, `BrowseShelves.swift`, `Equatable`, `ContentView`, `CodingKeys`, `BrewAction`?**
  _High betweenness centrality (0.143) - this node is a cross-community bridge._
- **Why does `CodingKeys` connect `CodingKeys` to `String`, `Equatable`, `Decodable`?**
  _High betweenness centrality (0.077) - this node is a cross-community bridge._
- **Are the 11 inferred relationships involving `CatalogPackage` (e.g. with `.body` and `.body`) actually correct?**
  _`CatalogPackage` has 11 INFERRED edges - model-reasoned connections that need verification._
- **Are the 6 inferred relationships involving `PackageNodeID` (e.g. with `.inventory()` and `.refreshInventory()`) actually correct?**
  _`PackageNodeID` has 6 INFERRED edges - model-reasoned connections that need verification._
- **Are the 3 inferred relationships involving `BrewPackage` (e.g. with `.filteredPackages` and `.selectedPackage`) actually correct?**
  _`BrewPackage` has 3 INFERRED edges - model-reasoned connections that need verification._
- **What connects `PackageDescription`, `build-app.sh script`, `run-app.sh script` to the rest of the system?**
  _166 weakly-connected nodes found - possible documentation gaps or missing edges._