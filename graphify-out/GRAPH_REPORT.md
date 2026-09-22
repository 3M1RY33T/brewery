# Graph Report - brewery  (2026-09-22)

## Corpus Check
- 45 files · ~228,961 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 749 nodes · 1776 edges · 39 communities (35 shown, 4 thin omitted)
- Extraction: 91% EXTRACTED · 9% INFERRED · 0% AMBIGUOUS · INFERRED: 164 edges (avg confidence: 0.83)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `359daa4e`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- BrewServicing
- String
- PackageNodeID
- CatalogPackage
- LiveBrewService
- CategoryTileGrid
- CatalogCategory
- CatalogSection
- PackageIconView
- BreweryCoreTests
- BrowseShelves.swift
- PackageFilter
- BreweryCore
- README.md
- BrowseView
- Stream
- CursorTrackingView
- BrewPackage
- CatalogSearchResults
- Package.swift
- build-app.sh
- run-app.sh
- CodingKeys
- ContentView
- PackageKind
- CatalogSnapshot
- CodingKeys
- CodingKeys
- CatalogStore
- BrewAction
- PinnedStore
- .fixture
- .body
- Decodable
- Equatable
- .formulaPackages
- TileGridFramePreference
- Foundation
- AnalyticsItem

## God Nodes (most connected - your core abstractions)
1. `CatalogPackage` - 67 edges
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
- `StubFileManager` --references--> `String`  [EXTRACTED]
  Tests/BreweryCoreTests/BreweryCoreTests.swift → Sources/BreweryCore/BrewDetector.swift
- `MockCatalogFetcher` --implements--> `CatalogFetching`  [EXTRACTED]
  Tests/BreweryCoreTests/BreweryCoreTests.swift → Sources/BreweryCore/CatalogStore.swift
- `BreweryApp` --calls--> `PackageStore`  [INFERRED]
  Sources/Brewery/BreweryApp.swift → Sources/BreweryCore/PackageStore.swift
- `.body` --calls--> `ContentView`  [INFERRED]
  Sources/Brewery/BreweryApp.swift → Sources/Brewery/ContentView.swift

## Import Cycles
- None detected.

## Communities (39 total, 4 thin omitted)

### Community 0 - "BrewServicing"
Cohesion: 0.17
Nodes (10): AnyObject, .body, .header, DiagnosticsBlock, .body, .report, BrewServicing, Sendable (+2 more)

### Community 1 - "String"
Cohesion: 0.19
Nodes (12): CodingKey, String, .nilIfEmpty, DynamicCodingKey, Int, CaskAppArtifact, CaskAppArtifactEntry, CaskArtifactEntry (+4 more)

### Community 2 - "PackageNodeID"
Cohesion: 0.10
Nodes (20): Codable, Comparable, Hashable, KeyPath, BrewDependencyGraph, BrewInventory, DependencyEdge, .isDirectRelationship (+12 more)

### Community 3 - "CatalogPackage"
Cohesion: 0.15
Nodes (21): Encoder, CompactIconGrid, .body, .searchResults, CaskShelfRow, .body, CatalogCard, .body (+13 more)

### Community 4 - "LiveBrewService"
Cohesion: 0.05
Nodes (35): CoreGraphics, FileManager, Int32, JSONDecoder, LocalizedError, MissingHomebrewView, .body, BrewDetectionReport (+27 more)

### Community 5 - "CategoryTileGrid"
Cohesion: 0.13
Nodes (16): CategoryTileGrid, .body, .canToggle, .collapsedCount, .columnCount, .visible, ShowMoreButton, .body (+8 more)

### Community 6 - "CatalogCategory"
Cohesion: 0.07
Nodes (30): CatalogCategory, ai, .assignable, communication, data, design, developerTools, featured (+22 more)

### Community 7 - "CatalogSection"
Cohesion: 0.16
Nodes (12): CatalogInstallStatus, installed, notInstalled, .title, CatalogSection, .id, .isEmpty, Bool (+4 more)

### Community 8 - "PackageIconView"
Cohesion: 0.07
Nodes (31): ImageIO, Never, Sendable, IconError, unusable, NSImage, PackageIconLoader, PackageIconView (+23 more)

### Community 9 - "BreweryCoreTests"
Cohesion: 0.09
Nodes (11): PackageIconResolver, PackageIconSource, appBundle, remote, Bool, FileManager, Set, URL (+3 more)

### Community 10 - "BrowseShelves.swift"
Cohesion: 0.18
Nodes (24): .grid, ChartRow, .body, Color, CompactCell, .body, HeroCard, .body (+16 more)

### Community 11 - "PackageFilter"
Cohesion: 0.18
Nodes (11): Identifiable, SidebarView, .body, PackageFilter, browse, casks, diagnostics, formulae (+3 more)

### Community 12 - "BreweryCore"
Cohesion: 0.26
Nodes (3): AppKit, BreweryCore, SwiftUI

### Community 13 - "README.md"
Cohesion: 0.17
Nodes (11): Browse the whole catalog, Build from source, Credits, Diagnostics, Features, Install, [Install Homebrew on macOS:](https://brew.sh/), Notes (+3 more)

### Community 14 - "BrowseView"
Cohesion: 0.26
Nodes (8): ScrollViewProxy, ShelfHeader, .body, BrowseView, .body, .pinnedResults, .body, CGFloat

### Community 15 - "Stream"
Cohesion: 0.50
Nodes (4): Stream, status, stderr, stdout

### Community 16 - "CursorTrackingView"
Cohesion: 0.11
Nodes (14): NSEvent, NSObjectProtocol, NSTrackingArea, NSView, NSViewRepresentable, NSWindow, CursorTrackingView, .body (+6 more)

### Community 17 - "BrewPackage"
Cohesion: 0.05
Nodes (55): Accessory, Content, CatalogPackageDetailView, .body, CaskGridView, .body, .emptyState, InstalledCaskCard (+47 more)

### Community 18 - "CatalogSearchResults"
Cohesion: 0.17
Nodes (6): CatalogSearchResults, .isEmpty, CatalogSearch, Bool, Int, Set

### Community 22 - "CodingKeys"
Cohesion: 0.07
Nodes (27): CodingKeys, artifacts, casks, caveats, currentVersion, declaredDirectly, dependencies, dependsOn (+19 more)

### Community 23 - "ContentView"
Cohesion: 0.31
Nodes (8): Gesture, ContentView, .clampedDetailPaneWidth, .mainInterface, .packageSearchHeader, DetailPaneResizeHandle, CGRect, Double

### Community 24 - "PackageKind"
Cohesion: 0.25
Nodes (6): CaseIterable, PackageKind, cask, formula, .id, .title

### Community 25 - "CatalogSnapshot"
Cohesion: 0.39
Nodes (3): CatalogSnapshot, .isCurrent, Bool

### Community 26 - "CodingKeys"
Cohesion: 0.20
Nodes (10): CodingKeys, appBundleName, dependencies, description, displayName, homepage, kind, name (+2 more)

### Community 27 - "CodingKeys"
Cohesion: 0.15
Nodes (13): CodingKeys, artifacts, dependencies, dependsOn, desc, fullName, fullToken, homepage (+5 more)

### Community 28 - "CatalogStore"
Cohesion: 0.15
Nodes (14): CatalogError, .errorDescription, httpStatus, noCachedCatalog, staleCacheFormat, CatalogFetching, CatalogStore, .isSearching (+6 more)

### Community 29 - "BrewAction"
Cohesion: 0.13
Nodes (13): BrewAction, .arguments, cleanup, .commandDisplay, .id, install, .isMutating, .title (+5 more)

### Community 30 - "PinnedStore"
Cohesion: 0.13
Nodes (14): App, ObservableObject, Scene, BreweryApp, .body, DetailPinButton, .body, PinnedStore (+6 more)

### Community 31 - ".fixture"
Cohesion: 0.36
Nodes (5): Error, MockCatalogFetcher, NotStubbed, Data, URL

### Community 32 - ".body"
Cohesion: 0.38
Nodes (6): ConfirmationSheet, .body, InstallSheet, .body, Void, .body

### Community 33 - "Decodable"
Cohesion: 0.22
Nodes (15): Decodable, .columns, .split, BrewInfoPayload, BrewPackageMapper, CaskInfo, FormulaInfo, IgnoredJSONValue (+7 more)

### Community 34 - "Equatable"
Cohesion: 0.22
Nodes (7): Equatable, CaskDependency, FlexibleDependencyMap, FlexibleDependencyValue, FlexibleStringList, Decoder, CaskCatalogItem

### Community 36 - ".formulaPackages"
Cohesion: 0.46
Nodes (4): CatalogPackageMapper, Data, Int, popularity

### Community 37 - "TileGridFramePreference"
Cohesion: 0.67
Nodes (3): PreferenceKey, CGRect, TileGridFramePreference

### Community 41 - "AnalyticsItem"
Cohesion: 0.50
Nodes (4): AnalyticsItem, .installs, .name, AnalyticsPayload

## Knowledge Gaps
- **175 isolated node(s):** `PackageDescription`, `build-app.sh script`, `run-app.sh script`, `.body`, `.isPinned` (+170 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `BrewServicing`, `PackageNodeID`, `CatalogPackage`, `LiveBrewService`, `CategoryTileGrid`, `CatalogCategory`, `CatalogSection`, `PackageIconView`, `BreweryCoreTests`, `PackageFilter`, `BrowseView`, `Stream`, `BrewPackage`, `CatalogSearchResults`, `CodingKeys`, `PackageKind`, `CodingKeys`, `CodingKeys`, `CatalogStore`, `BrewAction`, `PinnedStore`, `.fixture`, `.body`, `Decodable`, `Equatable`, `.formulaPackages`, `AnalyticsItem`?**
  _High betweenness centrality (0.500) - this node is a cross-community bridge._
- **Why does `CatalogPackage` connect `CatalogPackage` to `String`, `PackageNodeID`, `CategoryTileGrid`, `CatalogSection`, `PackageIconView`, `BreweryCoreTests`, `BrowseShelves.swift`, `PackageFilter`, `BrowseView`, `BrewPackage`, `CatalogSearchResults`, `ContentView`, `PackageKind`, `CatalogSnapshot`, `CodingKeys`, `CatalogStore`, `PinnedStore`, `Equatable`, `.formulaPackages`, `Foundation`?**
  _High betweenness centrality (0.144) - this node is a cross-community bridge._
- **Why does `BrewPackage` connect `BrewPackage` to `Decodable`, `PackageNodeID`, `Equatable`, `String`, `LiveBrewService`, `PackageIconView`, `BreweryCoreTests`, `PackageFilter`, `BrowseView`, `CatalogSearchResults`, `PackageKind`, `CatalogSnapshot`?**
  _High betweenness centrality (0.073) - this node is a cross-community bridge._
- **Are the 11 inferred relationships involving `CatalogPackage` (e.g. with `.body` and `.body`) actually correct?**
  _`CatalogPackage` has 11 INFERRED edges - model-reasoned connections that need verification._
- **Are the 5 inferred relationships involving `BrewPackage` (e.g. with `.body` and `.filteredPackages`) actually correct?**
  _`BrewPackage` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Are the 7 inferred relationships involving `PackageNodeID` (e.g. with `.inventory()` and `.refreshInventory()`) actually correct?**
  _`PackageNodeID` has 7 INFERRED edges - model-reasoned connections that need verification._
- **What connects `PackageDescription`, `build-app.sh script`, `run-app.sh script` to the rest of the system?**
  _175 weakly-connected nodes found - possible documentation gaps or missing edges._