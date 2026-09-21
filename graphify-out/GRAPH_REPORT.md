# Graph Report - brewery  (2026-09-21)

## Corpus Check
- 42 files · ~223,881 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 641 nodes · 1504 edges · 31 communities (27 shown, 4 thin omitted)
- Extraction: 91% EXTRACTED · 9% INFERRED · 0% AMBIGUOUS · INFERRED: 128 edges (avg confidence: 0.83)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `531c4860`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- CatalogInstallStatus
- String
- PackageNodeID
- CatalogStore
- LiveBrewService
- BrewDetectionReport
- CatalogCategory
- ContentView.swift
- IconDiskCache
- BreweryCoreTests
- CatalogPackage
- BrewServicing
- BreweryCore
- README.md
- PackageFilter
- Equatable
- BrewPackage
- CatalogSection
- CodingKeys
- Package.swift
- build-app.sh
- run-app.sh
- CodingKeys
- Decodable
- ContentView
- Foundation
- CodingKeys
- CursorTrackingView
- .body
- PackageKind
- AnalyticsItem

## God Nodes (most connected - your core abstractions)
1. `CatalogPackage` - 61 edges
2. `PackageNodeID` - 43 edges
3. `BrewPackage` - 39 edges
4. `BreweryCoreTests` - 38 edges
5. `PackageStore` - 36 edges
6. `CodingKeys` - 34 edges
7. `CatalogCategory` - 33 edges
8. `CatalogStore` - 29 edges
9. `BrewAction` - 28 edges
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

## Communities (31 total, 4 thin omitted)

### Community 0 - "CatalogInstallStatus"
Cohesion: 0.17
Nodes (8): Combine, CatalogInstallStatus, installed, notInstalled, .title, CatalogSearchResults, .isEmpty, Bool

### Community 1 - "String"
Cohesion: 0.19
Nodes (11): CodingKey, String, .nilIfEmpty, DynamicCodingKey, Int, CaskAppArtifact, CaskAppArtifactEntry, CaskArtifactEntry (+3 more)

### Community 2 - "PackageNodeID"
Cohesion: 0.11
Nodes (20): Codable, Comparable, Hashable, KeyPath, .columns, .split, BrewDependencyGraph, BrewInventory (+12 more)

### Community 3 - "CatalogStore"
Cohesion: 0.08
Nodes (27): Error, ObservableObject, CatalogPackageMapper, Data, Int, CatalogSnapshot, .isCurrent, popularity (+19 more)

### Community 4 - "LiveBrewService"
Cohesion: 0.07
Nodes (28): Int32, JSONDecoder, LocalizedError, CommandLogView, .body, BrewActionDisplay, BrewDiagnostics, BrewServiceError (+20 more)

### Community 5 - "BrewDetectionReport"
Cohesion: 0.13
Nodes (11): CoreGraphics, FileManager, BrewDetectionReport, .isAvailable, BrewDetector, Bool, FileManager, StubFileManager (+3 more)

### Community 6 - "CatalogCategory"
Cohesion: 0.08
Nodes (26): CatalogCategory, ai, .assignable, communication, data, design, developerTools, featured (+18 more)

### Community 7 - "ContentView.swift"
Cohesion: 0.28
Nodes (6): AppKit, Context, NSViewRepresentable, DetailPaneResizeHandle, .body, ResizeCursorArea

### Community 8 - "IconDiskCache"
Cohesion: 0.09
Nodes (24): ImageIO, Never, NSImage, Sendable, IconError, unusable, PackageIconLoader, .body (+16 more)

### Community 9 - "BreweryCoreTests"
Cohesion: 0.09
Nodes (12): CatalogSearch, Bool, Int, Set, PackageIconResolver, PackageIconSource, appBundle, remote (+4 more)

### Community 10 - "CatalogPackage"
Cohesion: 0.08
Nodes (57): CGFloat, Encoder, ScrollViewProxy, CategoryTileGrid, .body, ChartRow, .body, Color (+49 more)

### Community 11 - "BrewServicing"
Cohesion: 0.14
Nodes (13): AnyObject, App, Scene, BreweryApp, .body, .header, DiagnosticsBlock, .body (+5 more)

### Community 13 - "README.md"
Cohesion: 0.17
Nodes (11): Browse the whole catalog, Build from source, Credits, Diagnostics, Features, Install, [Install Homebrew on macOS:](https://brew.sh/), Notes (+3 more)

### Community 14 - "PackageFilter"
Cohesion: 0.20
Nodes (10): PackageFilter, all, browse, casks, diagnostics, formulae, .id, outdated (+2 more)

### Community 15 - "Equatable"
Cohesion: 0.25
Nodes (9): Equatable, CaskDependency, CaskInfo, FlexibleDependencyMap, FlexibleDependencyValue, FlexibleStringList, Decoder, CaskArtifacts (+1 more)

### Community 16 - "BrewPackage"
Cohesion: 0.05
Nodes (44): CaskGridView, .body, .emptyState, InstalledCaskCard, .body, .version, Bool, Int (+36 more)

### Community 17 - "CatalogSection"
Cohesion: 0.27
Nodes (7): CatalogSection, .id, .isEmpty, Date, Decoder, Int, URL

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
Cohesion: 0.21
Nodes (10): CGRect, Gesture, ContentView, .clampedDetailPaneWidth, .mainInterface, .packageSearchHeader, Double, SidebarView (+2 more)

### Community 25 - "Foundation"
Cohesion: 0.22
Nodes (5): Foundation, CatalogShelfStyle, compactGrid, showcase, spotlight

### Community 26 - "CodingKeys"
Cohesion: 0.20
Nodes (10): CodingKeys, appBundleName, dependencies, description, displayName, homepage, kind, name (+2 more)

### Community 27 - "CursorTrackingView"
Cohesion: 0.33
Nodes (4): NSEvent, NSTrackingArea, NSView, CursorTrackingView

### Community 28 - ".body"
Cohesion: 0.25
Nodes (8): ConfirmationSheet, .body, InstallSheet, .body, Void, .body, MissingHomebrewView, .body

### Community 29 - "PackageKind"
Cohesion: 0.25
Nodes (7): CaseIterable, Identifiable, PackageKind, cask, formula, .id, .title

### Community 30 - "AnalyticsItem"
Cohesion: 0.50
Nodes (4): AnalyticsItem, .installs, .name, AnalyticsPayload

## Knowledge Gaps
- **159 isolated node(s):** `PackageDescription`, `build-app.sh script`, `run-app.sh script`, `.body`, `.body` (+154 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `CatalogInstallStatus`, `PackageNodeID`, `CatalogStore`, `LiveBrewService`, `BrewDetectionReport`, `CatalogCategory`, `IconDiskCache`, `BreweryCoreTests`, `CatalogPackage`, `BrewServicing`, `PackageFilter`, `Equatable`, `BrewPackage`, `CatalogSection`, `CodingKeys`, `CodingKeys`, `Decodable`, `ContentView`, `CodingKeys`, `.body`, `PackageKind`, `AnalyticsItem`?**
  _High betweenness centrality (0.511) - this node is a cross-community bridge._
- **Why does `CatalogPackage` connect `CatalogPackage` to `CatalogInstallStatus`, `String`, `PackageNodeID`, `CatalogStore`, `BreweryCoreTests`, `Equatable`, `CatalogSection`, `ContentView`, `CodingKeys`, `PackageKind`?**
  _High betweenness centrality (0.140) - this node is a cross-community bridge._
- **Why does `CodingKeys` connect `CodingKeys` to `String`, `Equatable`, `Decodable`?**
  _High betweenness centrality (0.079) - this node is a cross-community bridge._
- **Are the 9 inferred relationships involving `CatalogPackage` (e.g. with `.body` and `.body`) actually correct?**
  _`CatalogPackage` has 9 INFERRED edges - model-reasoned connections that need verification._
- **Are the 6 inferred relationships involving `PackageNodeID` (e.g. with `.inventory()` and `.refreshInventory()`) actually correct?**
  _`PackageNodeID` has 6 INFERRED edges - model-reasoned connections that need verification._
- **Are the 3 inferred relationships involving `BrewPackage` (e.g. with `.filteredPackages` and `.selectedPackage`) actually correct?**
  _`BrewPackage` has 3 INFERRED edges - model-reasoned connections that need verification._
- **What connects `PackageDescription`, `build-app.sh script`, `run-app.sh script` to the rest of the system?**
  _159 weakly-connected nodes found - possible documentation gaps or missing edges._