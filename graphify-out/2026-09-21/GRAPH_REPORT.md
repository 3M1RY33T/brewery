# Graph Report - brewery  (2026-09-21)

## Corpus Check
- 43 files · ~226,538 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 694 nodes · 1633 edges · 39 communities (34 shown, 5 thin omitted)
- Extraction: 91% EXTRACTED · 9% INFERRED · 0% AMBIGUOUS · INFERRED: 141 edges (avg confidence: 0.83)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `8597c4ce`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Equatable
- String
- PackageNodeID
- CatalogStore
- LiveBrewService
- BrowseView.swift
- CatalogCategory
- BreweryCore
- IconDiskCache
- BreweryCoreTests
- BrowseShelves.swift
- PackageStore
- CatalogSection
- README.md
- BrewPackage
- CursorTrackingView
- HeroCard
- OutdatedView
- Foundation
- Package.swift
- build-app.sh
- run-app.sh
- CodingKeys
- InstalledCaskCard
- View
- CGFloat
- CodingKeys
- CodingKeys
- Decodable
- BrewAction
- ContentView
- CommandLogEntry
- PackageIconView
- CatalogPackage
- .body
- PackageFilter
- CatalogShelfStyle
- AnalyticsItem
- .score

## God Nodes (most connected - your core abstractions)
1. `CatalogPackage` - 61 edges
2. `PackageNodeID` - 44 edges
3. `BreweryCoreTests` - 44 edges
4. `BrewPackage` - 43 edges
5. `PackageStore` - 38 edges
6. `CodingKeys` - 34 edges
7. `CatalogCategory` - 33 edges
8. `BrewAction` - 30 edges
9. `CatalogStore` - 30 edges
10. `PackageIconView` - 26 edges

## Surprising Connections (you probably didn't know these)
- `.visible` --references--> `CatalogSection`  [INFERRED]
  Sources/Brewery/BrowseShelves.swift → Sources/BreweryCore/CatalogPackage.swift
- `.body` --calls--> `PackageIconView`  [INFERRED]
  Sources/Brewery/BrowseView.swift → Sources/Brewery/PackageIconView.swift
- `.body` --calls--> `PackageIconView`  [INFERRED]
  Sources/Brewery/BrowseView.swift → Sources/Brewery/PackageIconView.swift
- `StubFileManager` --references--> `String`  [EXTRACTED]
  Tests/BreweryCoreTests/BreweryCoreTests.swift → Sources/BreweryCore/BrewDetector.swift
- `.selectedPackage` --references--> `BrewPackage`  [INFERRED]
  Sources/BreweryCore/PackageStore.swift → Sources/BreweryCore/BrewPackage.swift

## Import Cycles
- None detected.

## Communities (39 total, 5 thin omitted)

### Community 0 - "Equatable"
Cohesion: 0.25
Nodes (9): Equatable, CaskDependency, CaskInfo, FlexibleDependencyMap, FlexibleDependencyValue, FlexibleStringList, Decoder, CaskArtifacts (+1 more)

### Community 1 - "String"
Cohesion: 0.18
Nodes (12): CodingKey, String, .nilIfEmpty, DynamicCodingKey, Int, BrewDiagnostics, CaskAppArtifact, CaskAppArtifactEntry (+4 more)

### Community 2 - "PackageNodeID"
Cohesion: 0.10
Nodes (22): Codable, Comparable, Hashable, KeyPath, PackageKind, cask, formula, .id (+14 more)

### Community 3 - "CatalogStore"
Cohesion: 0.07
Nodes (30): Error, LocalizedError, ObservableObject, IconError, unusable, CatalogSnapshot, .isCurrent, Date (+22 more)

### Community 4 - "LiveBrewService"
Cohesion: 0.06
Nodes (32): CoreGraphics, FileManager, Int32, JSONDecoder, MissingHomebrewView, .body, BrewDetectionReport, .isAvailable (+24 more)

### Community 5 - "BrowseView.swift"
Cohesion: 0.19
Nodes (18): .searchResults, CaskShelfRow, .body, CatalogCard, .body, CatalogShelf, .body, .casks (+10 more)

### Community 6 - "CatalogCategory"
Cohesion: 0.08
Nodes (24): CatalogCategory, ai, .assignable, communication, data, design, developerTools, featured (+16 more)

### Community 7 - "BreweryCore"
Cohesion: 0.13
Nodes (12): App, AppKit, BreweryCore, Scene, BreweryApp, DetailPaneResizeHandle, .body, DetailBlock (+4 more)

### Community 8 - "IconDiskCache"
Cohesion: 0.10
Nodes (22): ImageIO, Never, Sendable, .body, PackageIconLoader, ResolvedIcon, appBundle, downloaded (+14 more)

### Community 9 - "BreweryCoreTests"
Cohesion: 0.05
Nodes (24): .columns, .split, BrewPackageMapper, CatalogPackageMapper, Data, Int, CatalogSearchResults, .isEmpty (+16 more)

### Community 10 - "BrowseShelves.swift"
Cohesion: 0.15
Nodes (19): CategoryTileGrid, .body, .canToggle, .collapsedCount, .columnCount, .visible, ChartRow, CompactIconGrid (+11 more)

### Community 11 - "PackageStore"
Cohesion: 0.16
Nodes (12): AnyObject, .contentPane, DiagnosticsBlock, .body, DiagnosticsView, .body, PackageTableView, BrewServicing (+4 more)

### Community 12 - "CatalogSection"
Cohesion: 0.18
Nodes (9): Identifiable, CatalogInstallStatus, installed, notInstalled, .title, CatalogSection, .id, .isEmpty (+1 more)

### Community 13 - "README.md"
Cohesion: 0.17
Nodes (11): Browse the whole catalog, Build from source, Credits, Diagnostics, Features, Install, [Install Homebrew on macOS:](https://brew.sh/), Notes (+3 more)

### Community 14 - "BrewPackage"
Cohesion: 0.18
Nodes (10): DependencyNodeList, .body, PackageDetailView, .body, Void, .body, BrewPackage, Bool (+2 more)

### Community 15 - "CursorTrackingView"
Cohesion: 0.21
Nodes (7): Context, NSEvent, NSTrackingArea, NSView, NSViewRepresentable, CursorTrackingView, ResizeCursorArea

### Community 16 - "HeroCard"
Cohesion: 0.16
Nodes (15): .grid, .body, Color, .body, HeroCard, .body, .gradientStops, .body (+7 more)

### Community 17 - "OutdatedView"
Cohesion: 0.22
Nodes (10): Content, OutdatedFormulaRow, OutdatedView, .body, .casks, .emptyState, .formulae, Bool (+2 more)

### Community 22 - "CodingKeys"
Cohesion: 0.07
Nodes (27): CodingKeys, artifacts, casks, caveats, currentVersion, declaredDirectly, dependencies, dependsOn (+19 more)

### Community 23 - "InstalledCaskCard"
Cohesion: 0.20
Nodes (11): CaskGridView, .body, .emptyState, InstalledCaskCard, .body, InstalledVersionLabel, .body, Bool (+3 more)

### Community 24 - "View"
Cohesion: 0.40
Nodes (6): ScrollViewProxy, HeroCarousel, View, BrowseView, .body, .header

### Community 25 - "CGFloat"
Cohesion: 0.38
Nodes (5): PreferenceKey, CGFloat, WidthPreference, CGRect, TileGridFramePreference

### Community 26 - "CodingKeys"
Cohesion: 0.20
Nodes (10): CodingKeys, appBundleName, dependencies, description, displayName, homepage, kind, name (+2 more)

### Community 27 - "CodingKeys"
Cohesion: 0.15
Nodes (13): CodingKeys, artifacts, dependencies, dependsOn, desc, fullName, fullToken, homepage (+5 more)

### Community 28 - "Decodable"
Cohesion: 0.29
Nodes (11): Decodable, BrewInfoPayload, FormulaInfo, IgnoredJSONValue, Installed, OutdatedItem, OutdatedPayload, RuntimeDependency (+3 more)

### Community 29 - "BrewAction"
Cohesion: 0.09
Nodes (16): BrewAction, .arguments, cleanup, .commandDisplay, .id, install, .isMutating, .title (+8 more)

### Community 30 - "ContentView"
Cohesion: 0.25
Nodes (9): Gesture, ContentView, .clampedDetailPaneWidth, .mainInterface, .packageSearchHeader, CGRect, Double, SidebarView (+1 more)

### Community 31 - "CommandLogEntry"
Cohesion: 0.28
Nodes (7): CommandLogView, .body, CommandLogEntry, Stream, status, stderr, stdout

### Community 32 - "PackageIconView"
Cohesion: 0.21
Nodes (10): NSImage, PackageIconView, .body, .glyph, .glyphColor, .isFont, Bool, CGFloat (+2 more)

### Community 33 - "CatalogPackage"
Cohesion: 0.29
Nodes (8): Encoder, CompactCell, .body, SpotlightShelf, .body, CatalogPackageDetailView, .body, CatalogPackage

### Community 34 - ".body"
Cohesion: 0.40
Nodes (6): ConfirmationSheet, .body, InstallSheet, .body, Void, .body

### Community 35 - "PackageFilter"
Cohesion: 0.20
Nodes (10): CaseIterable, PackageFilter, browse, casks, diagnostics, formulae, .id, outdated (+2 more)

### Community 36 - "CatalogShelfStyle"
Cohesion: 0.40
Nodes (4): CatalogShelfStyle, compactGrid, showcase, spotlight

### Community 37 - "AnalyticsItem"
Cohesion: 0.50
Nodes (4): AnalyticsItem, .installs, .name, AnalyticsPayload

## Knowledge Gaps
- **171 isolated node(s):** `PackageDescription`, `build-app.sh script`, `run-app.sh script`, `.body`, `.body` (+166 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `Equatable`, `PackageNodeID`, `CatalogStore`, `LiveBrewService`, `BrowseView.swift`, `CatalogCategory`, `BreweryCore`, `IconDiskCache`, `BreweryCoreTests`, `BrowseShelves.swift`, `PackageStore`, `CatalogSection`, `BrewPackage`, `OutdatedView`, `CodingKeys`, `View`, `CodingKeys`, `CodingKeys`, `Decodable`, `BrewAction`, `ContentView`, `CommandLogEntry`, `PackageIconView`, `CatalogPackage`, `.body`, `PackageFilter`, `AnalyticsItem`, `.score`?**
  _High betweenness centrality (0.506) - this node is a cross-community bridge._
- **Why does `CatalogPackage` connect `CatalogPackage` to `PackageIconView`, `Equatable`, `PackageNodeID`, `String`, `CatalogStore`, `BrowseView.swift`, `BreweryCoreTests`, `BrowseShelves.swift`, `CatalogSection`, `BrewPackage`, `HeroCard`, `Foundation`, `View`, `CodingKeys`, `ContentView`?**
  _High betweenness centrality (0.132) - this node is a cross-community bridge._
- **Why does `CodingKeys` connect `CodingKeys` to `Equatable`, `String`, `Decodable`?**
  _High betweenness centrality (0.073) - this node is a cross-community bridge._
- **Are the 11 inferred relationships involving `CatalogPackage` (e.g. with `.body` and `.body`) actually correct?**
  _`CatalogPackage` has 11 INFERRED edges - model-reasoned connections that need verification._
- **Are the 7 inferred relationships involving `PackageNodeID` (e.g. with `.inventory()` and `.refreshInventory()`) actually correct?**
  _`PackageNodeID` has 7 INFERRED edges - model-reasoned connections that need verification._
- **What connects `PackageDescription`, `build-app.sh script`, `run-app.sh script` to the rest of the system?**
  _171 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `PackageNodeID` be split into smaller, more focused modules?**
  _Cohesion score 0.10101010101010101 - nodes in this community are weakly interconnected._