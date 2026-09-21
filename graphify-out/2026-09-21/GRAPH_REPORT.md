# Graph Report - brewery  (2026-09-21)

## Corpus Check
- 37 files · ~219,802 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 547 nodes · 1239 edges · 16 communities (13 shown, 3 thin omitted)
- Extraction: 92% EXTRACTED · 8% INFERRED · 0% AMBIGUOUS · INFERRED: 104 edges (avg confidence: 0.83)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `b947d5c9`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- BrewPackage
- String
- PackageNodeID
- CatalogStore
- LiveBrewService
- BrewDetectionReport
- BreweryCore
- IconDiskCache
- CatalogPackage
- README.md
- BreweryCoreTests
- BrewAction
- Package.swift
- build-app.sh
- run-app.sh
- CodingKeys

## God Nodes (most connected - your core abstractions)
1. `PackageNodeID` - 42 edges
2. `BrewPackage` - 37 edges
3. `PackageStore` - 36 edges
4. `CodingKeys` - 34 edges
5. `CatalogPackage` - 32 edges
6. `BreweryCoreTests` - 32 edges
7. `BrewAction` - 28 edges
8. `CatalogStore` - 26 edges
9. `PackageKind` - 23 edges
10. `BrewDependencyGraph` - 22 edges

## Surprising Connections (you probably didn't know these)
- `.body` --calls--> `PackageIconView`  [INFERRED]
  Sources/Brewery/BrowseView.swift → Sources/Brewery/PackageIconView.swift
- `.body` --calls--> `PackageIconView`  [INFERRED]
  Sources/Brewery/CaskGridView.swift → Sources/Brewery/PackageIconView.swift
- `StubFileManager` --references--> `String`  [EXTRACTED]
  Tests/BreweryCoreTests/BreweryCoreTests.swift → Sources/BreweryCore/BrewDetector.swift
- `.contentPane` --calls--> `BrowseView`  [INFERRED]
  Sources/Brewery/ContentView.swift → Sources/Brewery/BrowseView.swift
- `.body` --references--> `CatalogStore`  [INFERRED]
  Sources/Brewery/BrowseView.swift → Sources/BreweryCore/CatalogStore.swift

## Import Cycles
- None detected.

## Communities (16 total, 3 thin omitted)

### Community 0 - "BrewPackage"
Cohesion: 0.06
Nodes (50): AnyObject, App, Double, Gesture, Scene, BreweryApp, .body, .header (+42 more)

### Community 1 - "String"
Cohesion: 0.07
Nodes (45): CodingKey, Decodable, Equatable, String, .nilIfEmpty, BrewInfoPayload, BrewPackageMapper, CaskDependency (+37 more)

### Community 2 - "PackageNodeID"
Cohesion: 0.10
Nodes (20): Codable, Comparable, Hashable, KeyPath, BrewDependencyGraph, BrewInventory, DependencyEdge, .isDirectRelationship (+12 more)

### Community 3 - "CatalogStore"
Cohesion: 0.10
Nodes (21): ObservableObject, CatalogSnapshot, Date, CatalogError, .errorDescription, httpStatus, noCachedCatalog, CatalogFetching (+13 more)

### Community 4 - "LiveBrewService"
Cohesion: 0.07
Nodes (29): Color, Int32, JSONDecoder, LocalizedError, CommandLogView, .body, BrewActionDisplay, BrewDiagnostics (+21 more)

### Community 5 - "BrewDetectionReport"
Cohesion: 0.14
Nodes (10): FileManager, BrewDetectionReport, .isAvailable, BrewDetector, Bool, FileManager, Bool, StubFileManager (+2 more)

### Community 7 - "BreweryCore"
Cohesion: 0.07
Nodes (24): AppKit, BreweryCore, Context, CoreGraphics, ImageIO, NSEvent, NSTrackingArea, NSView (+16 more)

### Community 8 - "IconDiskCache"
Cohesion: 0.10
Nodes (24): CGFloat, Error, Never, NSImage, Sendable, IconError, unusable, PackageIconLoader (+16 more)

### Community 9 - "CatalogPackage"
Cohesion: 0.06
Nodes (40): Encoder, BrowseView, .body, .categoryStrip, CatalogCard, .body, CatalogPackageDetailView, .body (+32 more)

### Community 13 - "README.md"
Cohesion: 0.17
Nodes (11): Browse the whole catalog, Build from source, Credits, Diagnostics, Features, Install, [Install Homebrew on macOS:](https://brew.sh/), Notes (+3 more)

### Community 14 - "BreweryCoreTests"
Cohesion: 0.08
Nodes (14): CGRect, CatalogPackageMapper, Data, .isUncategorizedUtility, Bool, PackageIconResolver, PackageIconSource, appBundle (+6 more)

### Community 16 - "BrewAction"
Cohesion: 0.05
Nodes (37): CaseIterable, Combine, Foundation, Identifiable, BrewAction, .arguments, cleanup, .commandDisplay (+29 more)

### Community 22 - "CodingKeys"
Cohesion: 0.07
Nodes (27): CodingKeys, artifacts, casks, caveats, currentVersion, declaredDirectly, dependencies, dependsOn (+19 more)

## Knowledge Gaps
- **136 isolated node(s):** `PackageDescription`, `build-app.sh script`, `run-app.sh script`, `.emptyState`, `.version` (+131 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `BrewPackage`, `PackageNodeID`, `CatalogStore`, `LiveBrewService`, `BrewDetectionReport`, `BreweryCore`, `IconDiskCache`, `CatalogPackage`, `BreweryCoreTests`, `BrewAction`, `CodingKeys`?**
  _High betweenness centrality (0.516) - this node is a cross-community bridge._
- **Why does `CodingKeys` connect `CodingKeys` to `String`?**
  _High betweenness centrality (0.092) - this node is a cross-community bridge._
- **Why does `PackageStore` connect `BrewPackage` to `String`, `PackageNodeID`, `CatalogStore`, `LiveBrewService`, `BrewAction`?**
  _High betweenness centrality (0.092) - this node is a cross-community bridge._
- **Are the 6 inferred relationships involving `PackageNodeID` (e.g. with `.inventory()` and `.refreshInventory()`) actually correct?**
  _`PackageNodeID` has 6 INFERRED edges - model-reasoned connections that need verification._
- **Are the 3 inferred relationships involving `BrewPackage` (e.g. with `.filteredPackages` and `.selectedPackage`) actually correct?**
  _`BrewPackage` has 3 INFERRED edges - model-reasoned connections that need verification._
- **Are the 3 inferred relationships involving `PackageStore` (e.g. with `BreweryApp` and `.testPackageStoreExposesDependencyGraph()`) actually correct?**
  _`PackageStore` has 3 INFERRED edges - model-reasoned connections that need verification._
- **What connects `PackageDescription`, `build-app.sh script`, `run-app.sh script` to the rest of the system?**
  _136 weakly-connected nodes found - possible documentation gaps or missing edges._