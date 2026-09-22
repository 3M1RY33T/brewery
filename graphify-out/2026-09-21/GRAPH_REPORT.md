# Graph Report - brewery  (2026-09-21)

## Corpus Check
- 42 files · ~224,401 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 656 nodes · 1538 edges · 29 communities (26 shown, 3 thin omitted)
- Extraction: 91% EXTRACTED · 9% INFERRED · 0% AMBIGUOUS · INFERRED: 135 edges (avg confidence: 0.83)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `cf33aa21`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Foundation
- String
- PackageNodeID
- CatalogStore
- LiveBrewService
- BrowseView.swift
- CatalogCategory
- CursorTrackingView
- IconDiskCache
- BreweryCoreTests
- BrowseShelves.swift
- PackageStore
- CatalogPackage
- README.md
- View
- Equatable
- PackageIconView
- TopChartsShelf
- CodingKeys
- Package.swift
- build-app.sh
- run-app.sh
- CodingKeys
- Decodable
- BrowseView
- WidthPreference
- CodingKeys
- BrewAction
- AnalyticsItem

## God Nodes (most connected - your core abstractions)
1. `CatalogPackage` - 63 edges
2. `PackageNodeID` - 44 edges
3. `BreweryCoreTests` - 40 edges
4. `BrewPackage` - 39 edges
5. `PackageStore` - 37 edges
6. `CodingKeys` - 34 edges
7. `CatalogCategory` - 33 edges
8. `CatalogStore` - 30 edges
9. `BrewAction` - 28 edges
10. `PackageKind` - 24 edges

## Surprising Connections (you probably didn't know these)
- `.body` --calls--> `PackageIconView`  [INFERRED]
  Sources/Brewery/BrowseView.swift → Sources/Brewery/PackageIconView.swift
- `.body` --calls--> `PackageIconView`  [INFERRED]
  Sources/Brewery/BrowseView.swift → Sources/Brewery/PackageIconView.swift
- `.body` --calls--> `PackageIconView`  [INFERRED]
  Sources/Brewery/CaskGridView.swift → Sources/Brewery/PackageIconView.swift
- `StubFileManager` --references--> `String`  [EXTRACTED]
  Tests/BreweryCoreTests/BreweryCoreTests.swift → Sources/BreweryCore/BrewDetector.swift
- `.visible` --references--> `CatalogSection`  [INFERRED]
  Sources/Brewery/BrowseShelves.swift → Sources/BreweryCore/CatalogPackage.swift

## Import Cycles
- None detected.

## Communities (29 total, 3 thin omitted)

### Community 0 - "Foundation"
Cohesion: 0.10
Nodes (13): Combine, Foundation, CatalogInstallStatus, installed, notInstalled, .title, CatalogSearchResults, .isEmpty (+5 more)

### Community 1 - "String"
Cohesion: 0.18
Nodes (12): CodingKey, String, .nilIfEmpty, DynamicCodingKey, Int, BrewDiagnostics, CaskAppArtifact, CaskAppArtifactEntry (+4 more)

### Community 2 - "PackageNodeID"
Cohesion: 0.06
Nodes (33): Codable, Comparable, Hashable, KeyPath, .body, PackageKind, cask, formula (+25 more)

### Community 3 - "CatalogStore"
Cohesion: 0.08
Nodes (28): Error, ObservableObject, .header, CatalogPackageMapper, Data, Int, CatalogSnapshot, .isCurrent (+20 more)

### Community 4 - "LiveBrewService"
Cohesion: 0.06
Nodes (31): CoreGraphics, FileManager, Int32, JSONDecoder, LocalizedError, BrewDetectionReport, .isAvailable, BrewDetector (+23 more)

### Community 5 - "BrowseView.swift"
Cohesion: 0.19
Nodes (18): .searchResults, CaskShelfRow, .body, CatalogCard, .body, CatalogShelf, .casks, .subtitle (+10 more)

### Community 6 - "CatalogCategory"
Cohesion: 0.05
Nodes (40): CaseIterable, PackageFilter, browse, casks, diagnostics, formulae, .id, outdated (+32 more)

### Community 7 - "CursorTrackingView"
Cohesion: 0.18
Nodes (9): Context, NSEvent, NSTrackingArea, NSView, NSViewRepresentable, CursorTrackingView, DetailPaneResizeHandle, .body (+1 more)

### Community 8 - "IconDiskCache"
Cohesion: 0.09
Nodes (25): AppKit, ImageIO, Never, NSImage, Sendable, IconError, unusable, PackageIconLoader (+17 more)

### Community 9 - "BreweryCoreTests"
Cohesion: 0.10
Nodes (10): CGRect, PackageIconResolver, PackageIconSource, appBundle, remote, FileManager, URL, BreweryCoreTests (+2 more)

### Community 10 - "BrowseShelves.swift"
Cohesion: 0.17
Nodes (22): CategoryTileGrid, .body, .canToggle, .collapsedCount, .columnCount, ChartRow, CompactCell, CompactIconGrid (+14 more)

### Community 11 - "PackageStore"
Cohesion: 0.06
Nodes (41): AnyObject, App, BreweryCore, Gesture, Scene, BreweryApp, .body, CommandLogView (+33 more)

### Community 12 - "CatalogPackage"
Cohesion: 0.16
Nodes (15): Encoder, Identifiable, .visible, CatalogPackageDetailView, .body, CatalogPackage, .tintHue, CatalogSection (+7 more)

### Community 13 - "README.md"
Cohesion: 0.17
Nodes (11): Browse the whole catalog, Build from source, Credits, Diagnostics, Features, Install, [Install Homebrew on macOS:](https://brew.sh/), Notes (+3 more)

### Community 14 - "View"
Cohesion: 0.28
Nodes (10): DependencyNodeList, .body, DetailBlock, .body, DetailRow, .body, PackageDetailView, .body (+2 more)

### Community 15 - "Equatable"
Cohesion: 0.25
Nodes (9): Equatable, CaskDependency, CaskInfo, FlexibleDependencyMap, FlexibleDependencyValue, FlexibleStringList, Decoder, CaskArtifacts (+1 more)

### Community 16 - "PackageIconView"
Cohesion: 0.23
Nodes (10): .grid, .body, Color, .body, .body, InstallButton, .body, .body (+2 more)

### Community 17 - "TopChartsShelf"
Cohesion: 0.25
Nodes (8): ShelfHeader, .body, TopChartsShelf, .body, .canShowLess, .canShowMore, .longest, .body

### Community 18 - "CodingKeys"
Cohesion: 0.15
Nodes (13): CodingKeys, artifacts, dependencies, dependsOn, desc, fullName, fullToken, homepage (+5 more)

### Community 22 - "CodingKeys"
Cohesion: 0.07
Nodes (27): CodingKeys, artifacts, casks, caveats, currentVersion, declaredDirectly, dependencies, dependsOn (+19 more)

### Community 23 - "Decodable"
Cohesion: 0.29
Nodes (11): Decodable, BrewInfoPayload, FormulaInfo, IgnoredJSONValue, Installed, OutdatedItem, OutdatedPayload, RuntimeDependency (+3 more)

### Community 24 - "BrowseView"
Cohesion: 0.48
Nodes (3): ScrollViewProxy, BrowseView, .body

### Community 25 - "WidthPreference"
Cohesion: 0.67
Nodes (3): PreferenceKey, CGFloat, WidthPreference

### Community 26 - "CodingKeys"
Cohesion: 0.20
Nodes (10): CodingKeys, appBundleName, dependencies, description, displayName, homepage, kind, name (+2 more)

### Community 29 - "BrewAction"
Cohesion: 0.10
Nodes (21): CaskGridView, .body, .emptyState, InstalledCaskCard, .body, .version, Bool, Int (+13 more)

### Community 30 - "AnalyticsItem"
Cohesion: 0.50
Nodes (4): AnalyticsItem, .installs, .name, AnalyticsPayload

## Knowledge Gaps
- **165 isolated node(s):** `PackageDescription`, `build-app.sh script`, `run-app.sh script`, `.body`, `.body` (+160 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `Foundation`, `PackageNodeID`, `CatalogStore`, `LiveBrewService`, `BrowseView.swift`, `CatalogCategory`, `IconDiskCache`, `BreweryCoreTests`, `BrowseShelves.swift`, `PackageStore`, `CatalogPackage`, `View`, `Equatable`, `PackageIconView`, `TopChartsShelf`, `CodingKeys`, `CodingKeys`, `Decodable`, `CodingKeys`, `BrewAction`, `AnalyticsItem`?**
  _High betweenness centrality (0.508) - this node is a cross-community bridge._
- **Why does `CatalogPackage` connect `CatalogPackage` to `Foundation`, `String`, `PackageNodeID`, `CatalogStore`, `BrowseView.swift`, `BreweryCoreTests`, `BrowseShelves.swift`, `PackageStore`, `Equatable`, `PackageIconView`, `TopChartsShelf`, `BrowseView`, `CodingKeys`?**
  _High betweenness centrality (0.143) - this node is a cross-community bridge._
- **Why does `CodingKeys` connect `CodingKeys` to `String`, `Equatable`, `Decodable`?**
  _High betweenness centrality (0.077) - this node is a cross-community bridge._
- **Are the 11 inferred relationships involving `CatalogPackage` (e.g. with `.body` and `.body`) actually correct?**
  _`CatalogPackage` has 11 INFERRED edges - model-reasoned connections that need verification._
- **Are the 7 inferred relationships involving `PackageNodeID` (e.g. with `.inventory()` and `.refreshInventory()`) actually correct?**
  _`PackageNodeID` has 7 INFERRED edges - model-reasoned connections that need verification._
- **What connects `PackageDescription`, `build-app.sh script`, `run-app.sh script` to the rest of the system?**
  _165 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Foundation` be split into smaller, more focused modules?**
  _Cohesion score 0.09971509971509972 - nodes in this community are weakly interconnected._