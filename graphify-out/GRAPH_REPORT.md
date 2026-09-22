# Graph Report - brewery  (2026-09-22)

## Corpus Check
- 44 files · ~228,659 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 740 nodes · 1751 edges · 36 communities (33 shown, 3 thin omitted)
- Extraction: 91% EXTRACTED · 9% INFERRED · 0% AMBIGUOUS · INFERRED: 157 edges (avg confidence: 0.83)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `2435cb32`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- PackageStore
- String
- PackageNodeID
- BreweryCoreTests
- LiveBrewService
- CursorTrackingView
- CatalogCategory
- BrewPackage
- IconDiskCache
- .sources
- CatalogPackage
- PackageDetailView
- BreweryCore
- README.md
- InstalledCaskCard
- PackageManagementMenu
- ChromeView
- InstalledPackagesView
- CatalogSearchResults
- Package.swift
- build-app.sh
- run-app.sh
- CodingKeys
- ContentView
- DiagnosticsView
- CodingKeys
- CodingKeys
- CatalogStore
- BrewAction
- View
- .fixture
- InstallSheet
- Decodable
- Equatable
- .formulaPackages
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
- `.visible` --references--> `CatalogSection`  [INFERRED]
  Sources/Brewery/BrowseShelves.swift → Sources/BreweryCore/CatalogPackage.swift
- `.body` --calls--> `CommandLogView`  [INFERRED]
  Sources/Brewery/DiagnosticsView.swift → Sources/Brewery/CommandLogView.swift
- `StubFileManager` --references--> `String`  [EXTRACTED]
  Tests/BreweryCoreTests/BreweryCoreTests.swift → Sources/BreweryCore/BrewDetector.swift
- `MockCatalogFetcher` --implements--> `CatalogFetching`  [EXTRACTED]
  Tests/BreweryCoreTests/BreweryCoreTests.swift → Sources/BreweryCore/CatalogStore.swift
- `BreweryApp` --calls--> `PackageStore`  [INFERRED]
  Sources/Brewery/BreweryApp.swift → Sources/BreweryCore/PackageStore.swift

## Import Cycles
- None detected.

## Communities (36 total, 3 thin omitted)

### Community 0 - "PackageStore"
Cohesion: 0.20
Nodes (8): AnyObject, .body, BrewServicing, MockBrewService, URL, PackageStore, Sendable, Void

### Community 1 - "String"
Cohesion: 0.19
Nodes (11): CodingKey, String, .nilIfEmpty, DynamicCodingKey, Int, CaskAppArtifact, CaskAppArtifactEntry, CaskArtifactEntry (+3 more)

### Community 2 - "PackageNodeID"
Cohesion: 0.10
Nodes (20): Codable, Comparable, Hashable, KeyPath, .columns, .split, BrewDependencyGraph, BrewInventory (+12 more)

### Community 3 - "BreweryCoreTests"
Cohesion: 0.18
Nodes (3): BreweryCoreTests, Int, XCTestCase

### Community 4 - "LiveBrewService"
Cohesion: 0.05
Nodes (36): FileManager, Int32, JSONDecoder, CommandLogView, .body, BrewDetectionReport, .isAvailable, BrewDetector (+28 more)

### Community 5 - "CursorTrackingView"
Cohesion: 0.23
Nodes (6): NSEvent, NSTrackingArea, NSViewRepresentable, CursorTrackingView, ResizeCursorArea, Context

### Community 6 - "CatalogCategory"
Cohesion: 0.05
Nodes (43): CaseIterable, Identifiable, PackageKind, cask, formula, .id, .title, PackageFilter (+35 more)

### Community 7 - "BrewPackage"
Cohesion: 0.19
Nodes (7): Array, BrewPackage, Bool, URL, Bool, .filteredPackages, .selectedPackage

### Community 8 - "IconDiskCache"
Cohesion: 0.08
Nodes (24): ImageIO, Never, Sendable, .body, IconError, unusable, PackageIconLoader, ResolvedIcon (+16 more)

### Community 9 - ".sources"
Cohesion: 0.14
Nodes (8): PackageIconResolver, PackageIconSource, appBundle, remote, Bool, FileManager, Set, URL

### Community 10 - "CatalogPackage"
Cohesion: 0.07
Nodes (57): Encoder, CategoryTileGrid, .body, .canToggle, .collapsedCount, .columnCount, .grid, .visible (+49 more)

### Community 11 - "PackageDetailView"
Cohesion: 0.36
Nodes (5): DependencyNodeList, .body, PackageDetailView, .body, Void

### Community 12 - "BreweryCore"
Cohesion: 0.19
Nodes (9): App, BreweryCore, Scene, BreweryApp, MissingHomebrewView, .body, SidebarView, .body (+1 more)

### Community 13 - "README.md"
Cohesion: 0.17
Nodes (11): Browse the whole catalog, Build from source, Credits, Diagnostics, Features, Install, [Install Homebrew on macOS:](https://brew.sh/), Notes (+3 more)

### Community 14 - "InstalledCaskCard"
Cohesion: 0.32
Nodes (6): InstalledCaskCard, Bool, Int, Void, .body, .caskRow

### Community 15 - "PackageManagementMenu"
Cohesion: 0.33
Nodes (6): .body, InstalledVersionLabel, .body, .body, PackageManagementMenu, .body

### Community 16 - "ChromeView"
Cohesion: 0.20
Nodes (7): NSObjectProtocol, NSView, NSWindow, ChromeView, Context, View, WindowChrome

### Community 17 - "InstalledPackagesView"
Cohesion: 0.16
Nodes (13): Accessory, Content, .contentPane, InstalledCasksSheet, InstalledFormulaRow, InstalledPackagesView, .body, .casks (+5 more)

### Community 18 - "CatalogSearchResults"
Cohesion: 0.15
Nodes (6): CatalogSearchResults, .isEmpty, CatalogSearch, Bool, Int, Set

### Community 22 - "CodingKeys"
Cohesion: 0.07
Nodes (27): CodingKeys, artifacts, casks, caveats, currentVersion, declaredDirectly, dependencies, dependsOn (+19 more)

### Community 23 - "ContentView"
Cohesion: 0.23
Nodes (10): AppKit, Gesture, ContentView, .clampedDetailPaneWidth, .mainInterface, .packageSearchHeader, DetailPaneResizeHandle, .body (+2 more)

### Community 24 - "DiagnosticsView"
Cohesion: 0.40
Nodes (5): DiagnosticsBlock, .body, DiagnosticsView, .body, .report

### Community 26 - "CodingKeys"
Cohesion: 0.20
Nodes (10): CodingKeys, appBundleName, dependencies, description, displayName, homepage, kind, name (+2 more)

### Community 27 - "CodingKeys"
Cohesion: 0.15
Nodes (13): CodingKeys, artifacts, dependencies, dependsOn, desc, fullName, fullToken, homepage (+5 more)

### Community 28 - "CatalogStore"
Cohesion: 0.07
Nodes (32): Combine, Foundation, LocalizedError, CatalogInstallStatus, installed, notInstalled, .title, CatalogSection (+24 more)

### Community 29 - "BrewAction"
Cohesion: 0.11
Nodes (14): BrewAction, .arguments, cleanup, .commandDisplay, .id, install, .isMutating, .title (+6 more)

### Community 30 - "View"
Cohesion: 0.06
Nodes (44): ObservableObject, PreferenceKey, ScrollViewProxy, .body, BrowseView, .body, .header, .pinnedResults (+36 more)

### Community 31 - ".fixture"
Cohesion: 0.29
Nodes (7): CoreGraphics, Error, MockCatalogFetcher, NotStubbed, Data, URL, XCTest

### Community 32 - "InstallSheet"
Cohesion: 0.40
Nodes (5): ConfirmationSheet, .body, InstallSheet, .body, Void

### Community 33 - "Decodable"
Cohesion: 0.29
Nodes (11): Decodable, BrewInfoPayload, FormulaInfo, IgnoredJSONValue, Installed, OutdatedItem, OutdatedPayload, RuntimeDependency (+3 more)

### Community 34 - "Equatable"
Cohesion: 0.25
Nodes (9): Equatable, CaskDependency, CaskInfo, FlexibleDependencyMap, FlexibleDependencyValue, FlexibleStringList, Decoder, CaskArtifacts (+1 more)

### Community 36 - ".formulaPackages"
Cohesion: 0.39
Nodes (4): CatalogPackageMapper, Data, Int, popularity

### Community 41 - "AnalyticsItem"
Cohesion: 0.50
Nodes (4): AnalyticsItem, .installs, .name, AnalyticsPayload

## Knowledge Gaps
- **172 isolated node(s):** `PackageDescription`, `build-app.sh script`, `run-app.sh script`, `.body`, `.isPinned` (+167 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `PackageStore`, `PackageNodeID`, `LiveBrewService`, `CatalogCategory`, `BrewPackage`, `IconDiskCache`, `.sources`, `CatalogPackage`, `PackageDetailView`, `BreweryCore`, `InstalledPackagesView`, `CatalogSearchResults`, `CodingKeys`, `DiagnosticsView`, `CodingKeys`, `CodingKeys`, `CatalogStore`, `BrewAction`, `View`, `.fixture`, `InstallSheet`, `Decodable`, `Equatable`, `.formulaPackages`, `AnalyticsItem`?**
  _High betweenness centrality (0.502) - this node is a cross-community bridge._
- **Why does `CatalogPackage` connect `CatalogPackage` to `String`, `PackageNodeID`, `Equatable`, `.formulaPackages`, `BreweryCoreTests`, `CatalogCategory`, `CatalogSearchResults`, `ContentView`, `CodingKeys`, `CatalogStore`, `View`?**
  _High betweenness centrality (0.147) - this node is a cross-community bridge._
- **Why does `BrewPackage` connect `BrewPackage` to `PackageStore`, `String`, `PackageNodeID`, `Equatable`, `LiveBrewService`, `BreweryCoreTests`, `CatalogCategory`, `CatalogPackage`, `PackageDetailView`, `InstalledCaskCard`, `PackageManagementMenu`, `InstalledPackagesView`, `CatalogSearchResults`, `CatalogStore`, `BrewAction`, `View`?**
  _High betweenness centrality (0.074) - this node is a cross-community bridge._
- **Are the 11 inferred relationships involving `CatalogPackage` (e.g. with `.body` and `.body`) actually correct?**
  _`CatalogPackage` has 11 INFERRED edges - model-reasoned connections that need verification._
- **Are the 5 inferred relationships involving `BrewPackage` (e.g. with `.body` and `.filteredPackages`) actually correct?**
  _`BrewPackage` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Are the 7 inferred relationships involving `PackageNodeID` (e.g. with `.inventory()` and `.refreshInventory()`) actually correct?**
  _`PackageNodeID` has 7 INFERRED edges - model-reasoned connections that need verification._
- **What connects `PackageDescription`, `build-app.sh script`, `run-app.sh script` to the rest of the system?**
  _172 weakly-connected nodes found - possible documentation gaps or missing edges._