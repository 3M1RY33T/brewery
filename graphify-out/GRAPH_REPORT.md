# Graph Report - brewery  (2026-09-23)

## Corpus Check
- 44 files · ~295,212 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 754 nodes · 1778 edges · 31 communities (28 shown, 3 thin omitted)
- Extraction: 91% EXTRACTED · 9% INFERRED · 0% AMBIGUOUS · INFERRED: 158 edges (avg confidence: 0.83)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `2cc86b13`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- BreweryCore
- DynamicCodingKey
- PackageNodeID
- Foundation
- LiveBrewService
- PinnedStore
- CatalogCategory
- BrewPackage
- String
- .sources
- CatalogPackage
- View
- ContentView
- README.md
- PackageFilter
- InstalledCaskCard
- ChromeView
- InstalledPackagesView
- CommandLogEntry
- Package.swift
- build-app.sh
- run-app.sh
- CodingKeys
- BreweryCoreTests
- CodingKeys
- CodingKeys
- BrewAction
- BrowseView
- AnalyticsItem
- Equatable
- Decodable

## God Nodes (most connected - your core abstractions)
1. `CatalogPackage` - 67 edges
2. `BreweryCoreTests` - 50 edges
3. `BrewPackage` - 48 edges
4. `PackageNodeID` - 45 edges
5. `PackageStore` - 39 edges
6. `BrewAction` - 35 edges
7. `CodingKeys` - 34 edges
8. `CatalogStore` - 34 edges
9. `CatalogCategory` - 33 edges
10. `PackageIconView` - 25 edges

## Surprising Connections (you probably didn't know these)
- `.visible` --references--> `CatalogSection`  [INFERRED]
  Sources/Brewery/BrowseShelves.swift → Sources/BreweryCore/CatalogPackage.swift
- `BreweryApp` --calls--> `PackageStore`  [INFERRED]
  Sources/Brewery/BreweryApp.swift → Sources/BreweryCore/PackageStore.swift
- `BreweryApp` --calls--> `PinnedStore`  [INFERRED]
  Sources/Brewery/BreweryApp.swift → Sources/BreweryCore/PinnedStore.swift
- `.body` --calls--> `ContentView`  [INFERRED]
  Sources/Brewery/BreweryApp.swift → Sources/Brewery/ContentView.swift
- `.pinnedResults` --calls--> `ShelfHeader`  [INFERRED]
  Sources/Brewery/BrowseView.swift → Sources/Brewery/BrowseShelves.swift

## Import Cycles
- None detected.

## Communities (31 total, 3 thin omitted)

### Community 0 - "BreweryCore"
Cohesion: 0.07
Nodes (24): AnyObject, App, AppKit, BreweryCore, Scene, BreweryApp, .body, .header (+16 more)

### Community 1 - "DynamicCodingKey"
Cohesion: 0.20
Nodes (7): CodingKey, DynamicCodingKey, Int, CaskAppArtifact, CaskAppArtifactEntry, CaskArtifactEntry, Decoder

### Community 2 - "PackageNodeID"
Cohesion: 0.14
Nodes (16): Codable, Comparable, Hashable, KeyPath, BrewDependencyGraph, BrewInventory, DependencyEdge, .isDirectRelationship (+8 more)

### Community 3 - "Foundation"
Cohesion: 0.08
Nodes (20): Combine, Foundation, CatalogInstallStatus, installed, notInstalled, .title, CatalogSearchResults, .isEmpty (+12 more)

### Community 4 - "LiveBrewService"
Cohesion: 0.09
Nodes (21): Int32, JSONDecoder, BrewActionDisplay, BrewDiagnostics, BrewServiceError, brewNotFound, commandFailed, decodingFailed (+13 more)

### Community 5 - "PinnedStore"
Cohesion: 0.14
Nodes (11): ObservableObject, .body, DetailPinButton, .body, PinnedStore, .count, .isEmpty, Bool (+3 more)

### Community 6 - "CatalogCategory"
Cohesion: 0.07
Nodes (30): CatalogCategory, ai, .assignable, communication, data, design, developerTools, featured (+22 more)

### Community 7 - "BrewPackage"
Cohesion: 0.24
Nodes (10): InstalledCasksSheet, .body, .body, .caskRow, BrewPackage, Bool, URL, PackageStore (+2 more)

### Community 8 - "String"
Cohesion: 0.06
Nodes (38): FileManager, ImageIO, Never, Sendable, IconError, unusable, PackageIconLoader, ResolvedIcon (+30 more)

### Community 9 - ".sources"
Cohesion: 0.16
Nodes (8): PackageIconResolver, PackageIconSource, appBundle, remote, Bool, FileManager, Set, URL

### Community 10 - "CatalogPackage"
Cohesion: 0.07
Nodes (59): Encoder, NSColor, CategoryTileGrid, .body, .canToggle, .collapsedCount, .columnCount, .grid (+51 more)

### Community 11 - "View"
Cohesion: 0.21
Nodes (12): CatalogPackageDetailView, .body, DependencyNodeList, .body, DetailBlock, .body, DetailRow, .body (+4 more)

### Community 12 - "ContentView"
Cohesion: 0.22
Nodes (10): Gesture, ContentView, .clampedDetailPaneWidth, .isDetailPaneVisible, .mainInterface, DetailPaneResizeHandle, .body, Bool (+2 more)

### Community 13 - "README.md"
Cohesion: 0.15
Nodes (12): Browse the whole catalog, Build from source, Credits, Diagnostics, Features, Install, [Install Homebrew on macOS:](https://brew.sh/), Manage what is installed (+4 more)

### Community 14 - "PackageFilter"
Cohesion: 0.17
Nodes (10): CaseIterable, NavigationBar, .body, Array, PackageFilter, browse, diagnostics, .id (+2 more)

### Community 15 - "InstalledCaskCard"
Cohesion: 0.22
Nodes (10): InstalledCaskCard, .body, InstalledVersionLabel, .body, Bool, Int, Void, .body (+2 more)

### Community 16 - "ChromeView"
Cohesion: 0.09
Nodes (16): NSEvent, NSObjectProtocol, NSPoint, NSRect, NSTrackingArea, NSView, NSViewRepresentable, NSWindow (+8 more)

### Community 17 - "InstalledPackagesView"
Cohesion: 0.15
Nodes (11): Accessory, Content, .contentPane, InstalledFormulaRow, InstalledPackagesView, .casks, .emptyState, .formulae (+3 more)

### Community 18 - "CommandLogEntry"
Cohesion: 0.28
Nodes (7): Identifiable, CommandLogView, .body, DiagnosticsView, .body, Void, CommandLogEntry

### Community 22 - "CodingKeys"
Cohesion: 0.07
Nodes (27): CodingKeys, artifacts, casks, caveats, currentVersion, declaredDirectly, dependencies, dependsOn (+19 more)

### Community 23 - "BreweryCoreTests"
Cohesion: 0.05
Nodes (34): CoreGraphics, Error, LocalizedError, CatalogPackageMapper, Data, Int, CatalogSnapshot, .isCurrent (+26 more)

### Community 25 - "CodingKeys"
Cohesion: 0.20
Nodes (10): CodingKeys, appBundleName, dependencies, description, displayName, homepage, kind, name (+2 more)

### Community 27 - "CodingKeys"
Cohesion: 0.15
Nodes (13): CodingKeys, artifacts, dependencies, dependsOn, desc, fullName, fullToken, homepage (+5 more)

### Community 29 - "BrewAction"
Cohesion: 0.10
Nodes (18): BrewAction, .arguments, cleanup, .commandDisplay, .id, install, .isMutating, .title (+10 more)

### Community 30 - "BrowseView"
Cohesion: 0.12
Nodes (25): PreferenceKey, ScrollViewProxy, BrowseView, .body, .pinnedResults, .searchResults, CaskShelfRow, .body (+17 more)

### Community 31 - "AnalyticsItem"
Cohesion: 0.50
Nodes (4): AnalyticsItem, .installs, .name, AnalyticsPayload

### Community 34 - "Equatable"
Cohesion: 0.23
Nodes (8): Equatable, CaskDependency, FlexibleDependencyMap, FlexibleDependencyValue, FlexibleStringList, Decoder, CaskArtifacts, CaskCatalogItem

### Community 41 - "Decodable"
Cohesion: 0.19
Nodes (17): Decodable, .columns, Array, BrewInfoPayload, BrewPackageMapper, CaskInfo, FormulaInfo, IgnoredJSONValue (+9 more)

## Knowledge Gaps
- **174 isolated node(s):** `PackageDescription`, `build-app.sh script`, `run-app.sh script`, `.body`, `.isPinned` (+169 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `BreweryCore`, `DynamicCodingKey`, `PackageNodeID`, `Foundation`, `LiveBrewService`, `PinnedStore`, `CatalogCategory`, `BrewPackage`, `.sources`, `CatalogPackage`, `View`, `PackageFilter`, `InstalledPackagesView`, `CommandLogEntry`, `CodingKeys`, `BreweryCoreTests`, `CodingKeys`, `CodingKeys`, `BrewAction`, `BrowseView`, `AnalyticsItem`, `Equatable`, `Decodable`?**
  _High betweenness centrality (0.491) - this node is a cross-community bridge._
- **Why does `CatalogPackage` connect `CatalogPackage` to `PackageNodeID`, `Foundation`, `Equatable`, `PinnedStore`, `String`, `View`, `ContentView`, `CommandLogEntry`, `BreweryCoreTests`, `CodingKeys`, `BrewAction`, `BrowseView`?**
  _High betweenness centrality (0.153) - this node is a cross-community bridge._
- **Why does `BrewPackage` connect `BrewPackage` to `BreweryCore`, `PackageNodeID`, `Equatable`, `LiveBrewService`, `Foundation`, `String`, `Decodable`, `CatalogPackage`, `View`, `PackageFilter`, `InstalledCaskCard`, `InstalledPackagesView`, `CommandLogEntry`, `BreweryCoreTests`, `BrewAction`, `BrowseView`?**
  _High betweenness centrality (0.072) - this node is a cross-community bridge._
- **Are the 11 inferred relationships involving `CatalogPackage` (e.g. with `.body` and `.body`) actually correct?**
  _`CatalogPackage` has 11 INFERRED edges - model-reasoned connections that need verification._
- **Are the 5 inferred relationships involving `BrewPackage` (e.g. with `.body` and `.filteredPackages`) actually correct?**
  _`BrewPackage` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Are the 8 inferred relationships involving `PackageNodeID` (e.g. with `.inventory()` and `.refreshInventory()`) actually correct?**
  _`PackageNodeID` has 8 INFERRED edges - model-reasoned connections that need verification._
- **What connects `PackageDescription`, `build-app.sh script`, `run-app.sh script` to the rest of the system?**
  _174 weakly-connected nodes found - possible documentation gaps or missing edges._