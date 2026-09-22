# Graph Report - brewery  (2026-09-21)

## Corpus Check
- 43 files · ~227,052 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 702 nodes · 1657 edges · 32 communities (28 shown, 4 thin omitted)
- Extraction: 91% EXTRACTED · 9% INFERRED · 0% AMBIGUOUS · INFERRED: 146 edges (avg confidence: 0.83)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `6b10cedc`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Equatable
- String
- PackageNodeID
- CatalogStore
- LiveBrewService
- BrewDetectionReport
- CatalogCategory
- BreweryCore
- IconDiskCache
- BreweryCoreTests
- CatalogPackage
- PackageStore
- CatalogSection
- README.md
- PackageDetailView
- BrewPackage
- PackageKind
- OutdatedView
- Package.swift
- build-app.sh
- run-app.sh
- CodingKeys
- InstalledCaskCard
- CodingKeys
- CodingKeys
- Decodable
- BrewAction
- ContentView
- PackageFilter
- Foundation
- AnalyticsItem
- .score

## God Nodes (most connected - your core abstractions)
1. `CatalogPackage` - 61 edges
2. `BrewPackage` - 45 edges
3. `BreweryCoreTests` - 45 edges
4. `PackageNodeID` - 44 edges
5. `PackageStore` - 39 edges
6. `CodingKeys` - 34 edges
7. `BrewAction` - 33 edges
8. `CatalogCategory` - 33 edges
9. `CatalogStore` - 30 edges
10. `PackageIconView` - 26 edges

## Surprising Connections (you probably didn't know these)
- `.visible` --references--> `CatalogSection`  [INFERRED]
  Sources/Brewery/BrowseShelves.swift → Sources/BreweryCore/CatalogPackage.swift
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

## Communities (32 total, 4 thin omitted)

### Community 0 - "Equatable"
Cohesion: 0.25
Nodes (9): Equatable, CaskDependency, CaskInfo, FlexibleDependencyMap, FlexibleDependencyValue, FlexibleStringList, Decoder, CaskArtifacts (+1 more)

### Community 1 - "String"
Cohesion: 0.19
Nodes (11): CodingKey, String, .nilIfEmpty, DynamicCodingKey, Int, CaskAppArtifact, CaskAppArtifactEntry, CaskArtifactEntry (+3 more)

### Community 2 - "PackageNodeID"
Cohesion: 0.11
Nodes (20): Codable, Comparable, Hashable, KeyPath, .columns, .split, BrewDependencyGraph, BrewInventory (+12 more)

### Community 3 - "CatalogStore"
Cohesion: 0.06
Nodes (35): Combine, Error, ObservableObject, CatalogPackageMapper, Data, Int, CatalogInstallStatus, installed (+27 more)

### Community 4 - "LiveBrewService"
Cohesion: 0.07
Nodes (28): Int32, JSONDecoder, LocalizedError, CommandLogView, .body, BrewActionDisplay, BrewDiagnostics, BrewServiceError (+20 more)

### Community 5 - "BrewDetectionReport"
Cohesion: 0.13
Nodes (11): CoreGraphics, FileManager, BrewDetectionReport, .isAvailable, BrewDetector, Bool, FileManager, StubFileManager (+3 more)

### Community 6 - "CatalogCategory"
Cohesion: 0.08
Nodes (24): CatalogCategory, ai, .assignable, communication, data, design, developerTools, featured (+16 more)

### Community 7 - "BreweryCore"
Cohesion: 0.07
Nodes (25): App, BreweryCore, Context, NSEvent, NSTrackingArea, NSView, NSViewRepresentable, Scene (+17 more)

### Community 8 - "IconDiskCache"
Cohesion: 0.08
Nodes (26): AppKit, ImageIO, Never, Sendable, IconError, unusable, NSImage, PackageIconLoader (+18 more)

### Community 9 - "BreweryCoreTests"
Cohesion: 0.07
Nodes (15): CatalogSearch, Bool, Int, Set, PackageIconResolver, PackageIconSource, appBundle, remote (+7 more)

### Community 10 - "CatalogPackage"
Cohesion: 0.05
Nodes (77): Encoder, PreferenceKey, ScrollViewProxy, CategoryTileGrid, .body, .canToggle, .collapsedCount, .columnCount (+69 more)

### Community 11 - "PackageStore"
Cohesion: 0.22
Nodes (11): AnyObject, .body, .header, .body, DiagnosticsView, .body, BrewServicing, PackageStore (+3 more)

### Community 12 - "CatalogSection"
Cohesion: 0.24
Nodes (8): Identifiable, CatalogSection, .id, .isEmpty, Date, Decoder, Int, URL

### Community 13 - "README.md"
Cohesion: 0.17
Nodes (11): Browse the whole catalog, Build from source, Credits, Diagnostics, Features, Install, [Install Homebrew on macOS:](https://brew.sh/), Notes (+3 more)

### Community 14 - "PackageDetailView"
Cohesion: 0.26
Nodes (8): DependencyNodeList, DetailBlock, .body, DetailRow, .body, PackageDetailView, .body, Void

### Community 15 - "BrewPackage"
Cohesion: 0.13
Nodes (9): BrewPackage, Bool, URL, MockBrewService, Bool, Sendable, URL, .filteredPackages (+1 more)

### Community 16 - "PackageKind"
Cohesion: 0.29
Nodes (6): CaseIterable, PackageKind, cask, formula, .id, .title

### Community 17 - "OutdatedView"
Cohesion: 0.18
Nodes (12): Accessory, Content, OutdatedCasksSheet, OutdatedFormulaRow, OutdatedView, .body, .casks, .emptyState (+4 more)

### Community 22 - "CodingKeys"
Cohesion: 0.07
Nodes (27): CodingKeys, artifacts, casks, caveats, currentVersion, declaredDirectly, dependencies, dependsOn (+19 more)

### Community 23 - "InstalledCaskCard"
Cohesion: 0.15
Nodes (16): CaskGridView, .body, .emptyState, InstalledCaskCard, .body, InstalledVersionLabel, .body, Bool (+8 more)

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
Cohesion: 0.13
Nodes (13): BrewAction, .arguments, cleanup, .commandDisplay, .id, install, .isMutating, .title (+5 more)

### Community 30 - "ContentView"
Cohesion: 0.24
Nodes (8): Gesture, ContentView, .clampedDetailPaneWidth, .mainInterface, .packageSearchHeader, CGRect, Double, .body

### Community 35 - "PackageFilter"
Cohesion: 0.22
Nodes (9): PackageFilter, browse, casks, diagnostics, formulae, .id, outdated, pinned (+1 more)

### Community 36 - "Foundation"
Cohesion: 0.22
Nodes (5): Foundation, CatalogShelfStyle, compactGrid, showcase, spotlight

### Community 37 - "AnalyticsItem"
Cohesion: 0.50
Nodes (4): AnalyticsItem, .installs, .name, AnalyticsPayload

## Knowledge Gaps
- **172 isolated node(s):** `PackageDescription`, `build-app.sh script`, `run-app.sh script`, `.body`, `.body` (+167 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `Equatable`, `PackageNodeID`, `CatalogStore`, `LiveBrewService`, `BrewDetectionReport`, `CatalogCategory`, `BreweryCore`, `IconDiskCache`, `BreweryCoreTests`, `CatalogPackage`, `PackageStore`, `CatalogSection`, `PackageDetailView`, `BrewPackage`, `PackageKind`, `OutdatedView`, `CodingKeys`, `CodingKeys`, `CodingKeys`, `Decodable`, `BrewAction`, `PackageFilter`, `AnalyticsItem`, `.score`?**
  _High betweenness centrality (0.502) - this node is a cross-community bridge._
- **Why does `CatalogPackage` connect `CatalogPackage` to `Equatable`, `String`, `PackageNodeID`, `CatalogStore`, `BreweryCoreTests`, `CatalogSection`, `PackageKind`, `CodingKeys`, `ContentView`?**
  _High betweenness centrality (0.130) - this node is a cross-community bridge._
- **Why does `BrewPackage` connect `BrewPackage` to `Equatable`, `String`, `PackageNodeID`, `CatalogStore`, `Foundation`, `LiveBrewService`, `BreweryCoreTests`, `CatalogPackage`, `PackageStore`, `CatalogSection`, `PackageDetailView`, `PackageKind`, `OutdatedView`, `InstalledCaskCard`, `ContentView`?**
  _High betweenness centrality (0.073) - this node is a cross-community bridge._
- **Are the 11 inferred relationships involving `CatalogPackage` (e.g. with `.body` and `.body`) actually correct?**
  _`CatalogPackage` has 11 INFERRED edges - model-reasoned connections that need verification._
- **Are the 4 inferred relationships involving `BrewPackage` (e.g. with `.body` and `.filteredPackages`) actually correct?**
  _`BrewPackage` has 4 INFERRED edges - model-reasoned connections that need verification._
- **What connects `PackageDescription`, `build-app.sh script`, `run-app.sh script` to the rest of the system?**
  _172 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `PackageNodeID` be split into smaller, more focused modules?**
  _Cohesion score 0.1091753774680604 - nodes in this community are weakly interconnected._