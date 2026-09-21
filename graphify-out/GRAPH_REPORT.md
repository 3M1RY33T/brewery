# Graph Report - brewery  (2026-09-21)

## Corpus Check
- 41 files · ~222,182 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 599 nodes · 1384 edges · 31 communities (28 shown, 3 thin omitted)
- Extraction: 92% EXTRACTED · 8% INFERRED · 0% AMBIGUOUS · INFERRED: 112 edges (avg confidence: 0.83)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `b947d5c9`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- View
- String
- PackageNodeID
- BreweryCoreTests
- LiveBrewService
- BrewDetectionReport
- CatalogCategory
- CursorTrackingView
- IconDiskCache
- CatalogPackage
- BrowseView
- PackageStore
- BreweryCore
- README.md
- .sources
- Equatable
- BrewAction
- InstalledCaskCard
- CodingKeys
- Package.swift
- build-app.sh
- run-app.sh
- CodingKeys
- Decodable
- ContentView
- BrewJSON.swift
- CodingKeys
- .contentPane
- BrewPackage
- PackageIconView
- Stream

## God Nodes (most connected - your core abstractions)
1. `CatalogPackage` - 47 edges
2. `PackageNodeID` - 43 edges
3. `BrewPackage` - 39 edges
4. `BreweryCoreTests` - 38 edges
5. `PackageStore` - 36 edges
6. `CodingKeys` - 34 edges
7. `CatalogCategory` - 29 edges
8. `BrewAction` - 28 edges
9. `CatalogStore` - 28 edges
10. `PackageKind` - 24 edges

## Surprising Connections (you probably didn't know these)
- `.body` --calls--> `PackageIconView`  [INFERRED]
  Sources/Brewery/CaskGridView.swift → Sources/Brewery/PackageIconView.swift
- `StubFileManager` --references--> `String`  [EXTRACTED]
  Tests/BreweryCoreTests/BreweryCoreTests.swift → Sources/BreweryCore/BrewDetector.swift
- `BreweryApp` --calls--> `PackageStore`  [INFERRED]
  Sources/Brewery/BreweryApp.swift → Sources/BreweryCore/PackageStore.swift
- `.body` --calls--> `ContentView`  [INFERRED]
  Sources/Brewery/BreweryApp.swift → Sources/Brewery/ContentView.swift
- `.contentPane` --calls--> `BrowseView`  [INFERRED]
  Sources/Brewery/ContentView.swift → Sources/Brewery/BrowseView.swift

## Import Cycles
- None detected.

## Communities (31 total, 3 thin omitted)

### Community 0 - "View"
Cohesion: 0.25
Nodes (11): CatalogPackageDetailView, .body, DependencyNodeList, DetailBlock, .body, DetailRow, .body, PackageDetailView (+3 more)

### Community 1 - "String"
Cohesion: 0.19
Nodes (11): CodingKey, String, .nilIfEmpty, DynamicCodingKey, Int, CaskAppArtifact, CaskAppArtifactEntry, CaskArtifactEntry (+3 more)

### Community 2 - "PackageNodeID"
Cohesion: 0.11
Nodes (18): Comparable, Hashable, KeyPath, BrewDependencyGraph, BrewInventory, DependencyEdge, .isDirectRelationship, DependencyRelationship (+10 more)

### Community 3 - "BreweryCoreTests"
Cohesion: 0.06
Nodes (34): CGRect, Error, LocalizedError, ObservableObject, IconError, unusable, CatalogPackageMapper, Data (+26 more)

### Community 4 - "LiveBrewService"
Cohesion: 0.11
Nodes (20): Int32, JSONDecoder, BrewActionDisplay, BrewDiagnostics, BrewServiceError, brewNotFound, commandFailed, decodingFailed (+12 more)

### Community 5 - "BrewDetectionReport"
Cohesion: 0.14
Nodes (10): FileManager, BrewDetectionReport, .isAvailable, BrewDetector, Bool, FileManager, Bool, StubFileManager (+2 more)

### Community 6 - "CatalogCategory"
Cohesion: 0.09
Nodes (23): CatalogCategory, ai, .assignable, communication, data, design, developerTools, featured (+15 more)

### Community 7 - "CursorTrackingView"
Cohesion: 0.16
Nodes (10): AppKit, Context, NSEvent, NSTrackingArea, NSView, NSViewRepresentable, CursorTrackingView, DetailPaneResizeHandle (+2 more)

### Community 8 - "IconDiskCache"
Cohesion: 0.12
Nodes (20): Never, NSImage, Sendable, .body, PackageIconLoader, ResolvedIcon, appBundle, downloaded (+12 more)

### Community 9 - "CatalogPackage"
Cohesion: 0.08
Nodes (24): Codable, Encoder, Identifiable, CatalogInstallStatus, installed, notInstalled, .title, CatalogPackage (+16 more)

### Community 10 - "BrowseView"
Cohesion: 0.16
Nodes (19): ScrollViewProxy, BrowseView, .body, .header, .searchResults, .shelves, CaskShelfRow, .body (+11 more)

### Community 11 - "PackageStore"
Cohesion: 0.21
Nodes (10): AnyObject, Color, CommandLogView, .body, .body, BrewServicing, CommandLogEntry, PackageStore (+2 more)

### Community 12 - "BreweryCore"
Cohesion: 0.14
Nodes (11): App, BreweryCore, CoreGraphics, ImageIO, Scene, BreweryApp, MissingHomebrewView, .body (+3 more)

### Community 13 - "README.md"
Cohesion: 0.17
Nodes (11): Browse the whole catalog, Build from source, Credits, Diagnostics, Features, Install, [Install Homebrew on macOS:](https://brew.sh/), Notes (+3 more)

### Community 14 - ".sources"
Cohesion: 0.27
Nodes (6): PackageIconResolver, PackageIconSource, appBundle, remote, FileManager, URL

### Community 15 - "Equatable"
Cohesion: 0.23
Nodes (9): Equatable, CaskDependency, CaskInfo, FlexibleDependencyMap, FlexibleDependencyValue, FlexibleStringList, Decoder, CaskArtifacts (+1 more)

### Community 16 - "BrewAction"
Cohesion: 0.05
Nodes (35): CaseIterable, Combine, Foundation, ConfirmationSheet, .body, InstallSheet, .body, Void (+27 more)

### Community 17 - "InstalledCaskCard"
Cohesion: 0.19
Nodes (10): CaskGridView, .body, .emptyState, InstalledCaskCard, .body, .version, Bool, Int (+2 more)

### Community 18 - "CodingKeys"
Cohesion: 0.15
Nodes (13): CodingKeys, artifacts, dependencies, dependsOn, desc, fullName, fullToken, homepage (+5 more)

### Community 22 - "CodingKeys"
Cohesion: 0.07
Nodes (27): CodingKeys, artifacts, casks, caveats, currentVersion, declaredDirectly, dependencies, dependsOn (+19 more)

### Community 23 - "Decodable"
Cohesion: 0.27
Nodes (11): Decodable, FormulaInfo, Installed, RuntimeDependency, .packageName, Bool, Versions, AnalyticsItem (+3 more)

### Community 24 - "ContentView"
Cohesion: 0.25
Nodes (8): Double, Gesture, ContentView, .clampedDetailPaneWidth, .mainInterface, .packageSearchHeader, SidebarView, .body

### Community 25 - "BrewJSON.swift"
Cohesion: 0.33
Nodes (6): Array, BrewInfoPayload, BrewPackageMapper, IgnoredJSONValue, OutdatedItem, OutdatedPayload

### Community 26 - "CodingKeys"
Cohesion: 0.20
Nodes (10): CodingKeys, appBundleName, dependencies, description, displayName, homepage, kind, name (+2 more)

### Community 27 - ".contentPane"
Cohesion: 0.25
Nodes (6): .contentPane, DiagnosticsBlock, .body, DiagnosticsView, .body, .body

### Community 28 - "BrewPackage"
Cohesion: 0.32
Nodes (5): BrewPackage, Bool, URL, .filteredPackages, .selectedPackage

### Community 29 - "PackageIconView"
Cohesion: 0.40
Nodes (5): CGFloat, .body, .body, PackageIconView, .body

### Community 30 - "Stream"
Cohesion: 0.50
Nodes (4): Stream, status, stderr, stdout

## Knowledge Gaps
- **150 isolated node(s):** `PackageDescription`, `build-app.sh script`, `run-app.sh script`, `.body`, `.emptyState` (+145 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `View`, `PackageNodeID`, `BreweryCoreTests`, `LiveBrewService`, `BrewDetectionReport`, `CatalogCategory`, `IconDiskCache`, `CatalogPackage`, `BrowseView`, `PackageStore`, `.sources`, `Equatable`, `BrewAction`, `CodingKeys`, `CodingKeys`, `Decodable`, `ContentView`, `BrewJSON.swift`, `CodingKeys`, `.contentPane`, `BrewPackage`, `PackageIconView`, `Stream`?**
  _High betweenness centrality (0.522) - this node is a cross-community bridge._
- **Why does `CatalogPackage` connect `CatalogPackage` to `View`, `String`, `PackageNodeID`, `BreweryCoreTests`, `BrowseView`, `Equatable`, `BrewAction`, `ContentView`, `CodingKeys`, `PackageIconView`?**
  _High betweenness centrality (0.104) - this node is a cross-community bridge._
- **Why does `CodingKeys` connect `CodingKeys` to `BrewJSON.swift`, `Decodable`, `String`, `Equatable`?**
  _High betweenness centrality (0.084) - this node is a cross-community bridge._
- **Are the 7 inferred relationships involving `CatalogPackage` (e.g. with `.body` and `.body`) actually correct?**
  _`CatalogPackage` has 7 INFERRED edges - model-reasoned connections that need verification._
- **Are the 6 inferred relationships involving `PackageNodeID` (e.g. with `.inventory()` and `.refreshInventory()`) actually correct?**
  _`PackageNodeID` has 6 INFERRED edges - model-reasoned connections that need verification._
- **Are the 3 inferred relationships involving `BrewPackage` (e.g. with `.filteredPackages` and `.selectedPackage`) actually correct?**
  _`BrewPackage` has 3 INFERRED edges - model-reasoned connections that need verification._
- **What connects `PackageDescription`, `build-app.sh script`, `run-app.sh script` to the rest of the system?**
  _150 weakly-connected nodes found - possible documentation gaps or missing edges._