# Graph Report - brewery  (2026-09-21)

## Corpus Check
- 43 files · ~227,395 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 708 nodes · 1678 edges · 35 communities (30 shown, 5 thin omitted)
- Extraction: 91% EXTRACTED · 9% INFERRED · 0% AMBIGUOUS · INFERRED: 149 edges (avg confidence: 0.83)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `d608a4bd`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Equatable
- DynamicCodingKey
- PackageNodeID
- CatalogStore
- LiveBrewService
- String
- CatalogCategory
- BreweryCore
- PackageIconView
- BreweryCoreTests
- CatalogPackage
- PackageStore
- CatalogSection
- README.md
- BrewPackage
- .body
- CursorTrackingView
- InstalledPackagesView
- CatalogSearchResults
- Package.swift
- build-app.sh
- run-app.sh
- CodingKeys
- InstalledCaskCard
- Foundation
- CatalogSnapshot
- CodingKeys
- CodingKeys
- CatalogError
- BrewAction
- ContentView
- CatalogInstallStatus
- PackageFilter
- CatalogShelfStyle
- .score

## God Nodes (most connected - your core abstractions)
1. `CatalogPackage` - 61 edges
2. `BrewPackage` - 46 edges
3. `BreweryCoreTests` - 46 edges
4. `PackageNodeID` - 44 edges
5. `PackageStore` - 40 edges
6. `BrewAction` - 36 edges
7. `CodingKeys` - 34 edges
8. `CatalogCategory` - 33 edges
9. `CatalogStore` - 31 edges
10. `PackageIconView` - 26 edges

## Surprising Connections (you probably didn't know these)
- `.visible` --references--> `CatalogSection`  [INFERRED]
  Sources/Brewery/BrowseShelves.swift → Sources/BreweryCore/CatalogPackage.swift
- `.filteredPackages` --references--> `BrewPackage`  [INFERRED]
  Sources/BreweryCore/PackageStore.swift → Sources/BreweryCore/BrewPackage.swift
- `.selectedPackage` --references--> `BrewPackage`  [INFERRED]
  Sources/BreweryCore/PackageStore.swift → Sources/BreweryCore/BrewPackage.swift
- `MockCatalogFetcher` --implements--> `CatalogFetching`  [EXTRACTED]
  Tests/BreweryCoreTests/BreweryCoreTests.swift → Sources/BreweryCore/CatalogStore.swift
- `BreweryApp` --calls--> `PackageStore`  [INFERRED]
  Sources/Brewery/BreweryApp.swift → Sources/BreweryCore/PackageStore.swift

## Import Cycles
- None detected.

## Communities (35 total, 5 thin omitted)

### Community 0 - "Equatable"
Cohesion: 0.14
Nodes (24): Decodable, Equatable, .columns, .split, Array, BrewInfoPayload, BrewPackageMapper, CaskDependency (+16 more)

### Community 1 - "DynamicCodingKey"
Cohesion: 0.20
Nodes (7): CodingKey, DynamicCodingKey, Int, CaskAppArtifact, CaskAppArtifactEntry, CaskArtifactEntry, Decoder

### Community 2 - "PackageNodeID"
Cohesion: 0.14
Nodes (16): Codable, Comparable, Hashable, KeyPath, BrewDependencyGraph, BrewInventory, DependencyEdge, .isDirectRelationship (+8 more)

### Community 3 - "CatalogStore"
Cohesion: 0.16
Nodes (10): ObservableObject, CatalogStore, .isSearching, .searchResults, Bool, TimeInterval, URL, MockBrewService (+2 more)

### Community 4 - "LiveBrewService"
Cohesion: 0.07
Nodes (29): Int32, JSONDecoder, LocalizedError, CommandLogView, .body, BrewActionDisplay, BrewDiagnostics, BrewServiceError (+21 more)

### Community 5 - "String"
Cohesion: 0.16
Nodes (13): FileManager, BrewDetectionReport, .isAvailable, BrewDetector, String, .nilIfEmpty, Bool, FileManager (+5 more)

### Community 6 - "CatalogCategory"
Cohesion: 0.08
Nodes (24): CatalogCategory, ai, .assignable, communication, data, design, developerTools, featured (+16 more)

### Community 7 - "BreweryCore"
Cohesion: 0.13
Nodes (14): App, BreweryCore, Scene, BreweryApp, DiagnosticsBlock, .body, DiagnosticsView, .body (+6 more)

### Community 8 - "PackageIconView"
Cohesion: 0.06
Nodes (39): ImageIO, Never, Sendable, .body, .body, IconError, unusable, NSImage (+31 more)

### Community 9 - "BreweryCoreTests"
Cohesion: 0.07
Nodes (18): CoreGraphics, Error, PackageIconResolver, PackageIconSource, appBundle, remote, Bool, FileManager (+10 more)

### Community 10 - "CatalogPackage"
Cohesion: 0.06
Nodes (68): Encoder, PreferenceKey, ScrollViewProxy, CategoryTileGrid, .body, .canToggle, .collapsedCount, .columnCount (+60 more)

### Community 11 - "PackageStore"
Cohesion: 0.20
Nodes (7): AnyObject, BrewServicing, PackageStore, .filteredPackages, .selectedPackage, Sendable, Void

### Community 12 - "CatalogSection"
Cohesion: 0.24
Nodes (8): Identifiable, CatalogSection, .id, .isEmpty, Date, Decoder, Int, URL

### Community 13 - "README.md"
Cohesion: 0.17
Nodes (11): Browse the whole catalog, Build from source, Credits, Diagnostics, Features, Install, [Install Homebrew on macOS:](https://brew.sh/), Notes (+3 more)

### Community 14 - "BrewPackage"
Cohesion: 0.16
Nodes (15): .body, .caskRow, DependencyNodeList, .body, DetailBlock, .body, DetailRow, .body (+7 more)

### Community 15 - ".body"
Cohesion: 0.32
Nodes (6): ConfirmationSheet, .body, InstallSheet, .body, Void, .body

### Community 16 - "CursorTrackingView"
Cohesion: 0.16
Nodes (10): AppKit, Context, NSEvent, NSTrackingArea, NSView, NSViewRepresentable, CursorTrackingView, DetailPaneResizeHandle (+2 more)

### Community 17 - "InstalledPackagesView"
Cohesion: 0.14
Nodes (16): Accessory, Content, .contentPane, InstalledCasksSheet, InstalledFormulaRow, .body, InstalledPackagesView, .body (+8 more)

### Community 18 - "CatalogSearchResults"
Cohesion: 0.18
Nodes (6): CatalogSearchResults, .isEmpty, CatalogSearch, Bool, Int, Set

### Community 22 - "CodingKeys"
Cohesion: 0.07
Nodes (27): CodingKeys, artifacts, casks, caveats, currentVersion, declaredDirectly, dependencies, dependsOn (+19 more)

### Community 23 - "InstalledCaskCard"
Cohesion: 0.23
Nodes (10): CaskGridView, .body, .emptyState, InstalledCaskCard, .body, InstalledVersionLabel, .body, Bool (+2 more)

### Community 24 - "Foundation"
Cohesion: 0.27
Nodes (4): Combine, Foundation, CatalogFetching, URLSessionCatalogFetcher

### Community 26 - "CodingKeys"
Cohesion: 0.12
Nodes (18): AnalyticsItem, .installs, .name, AnalyticsPayload, CatalogPackageMapper, Data, Int, CodingKeys (+10 more)

### Community 27 - "CodingKeys"
Cohesion: 0.15
Nodes (13): CodingKeys, artifacts, dependencies, dependsOn, desc, fullName, fullToken, homepage (+5 more)

### Community 28 - "CatalogError"
Cohesion: 0.22
Nodes (7): CatalogError, .errorDescription, httpStatus, noCachedCatalog, staleCacheFormat, Data, Int

### Community 29 - "BrewAction"
Cohesion: 0.13
Nodes (13): BrewAction, .arguments, cleanup, .commandDisplay, .id, install, .isMutating, .title (+5 more)

### Community 30 - "ContentView"
Cohesion: 0.25
Nodes (10): Gesture, .body, .header, ContentView, .clampedDetailPaneWidth, .mainInterface, .packageSearchHeader, CGRect (+2 more)

### Community 31 - "CatalogInstallStatus"
Cohesion: 0.33
Nodes (5): CatalogInstallStatus, installed, notInstalled, .title, Bool

### Community 35 - "PackageFilter"
Cohesion: 0.17
Nodes (11): CaseIterable, PackageFilter, browse, casks, diagnostics, formulae, .id, library (+3 more)

### Community 36 - "CatalogShelfStyle"
Cohesion: 0.40
Nodes (4): CatalogShelfStyle, compactGrid, showcase, spotlight

## Knowledge Gaps
- **174 isolated node(s):** `PackageDescription`, `build-app.sh script`, `run-app.sh script`, `.body`, `.body` (+169 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `Equatable`, `DynamicCodingKey`, `PackageNodeID`, `LiveBrewService`, `CatalogCategory`, `BreweryCore`, `PackageIconView`, `BreweryCoreTests`, `CatalogPackage`, `PackageStore`, `CatalogSection`, `BrewPackage`, `.body`, `InstalledPackagesView`, `CatalogSearchResults`, `CodingKeys`, `CodingKeys`, `CodingKeys`, `CatalogError`, `BrewAction`, `CatalogInstallStatus`, `PackageFilter`, `.score`?**
  _High betweenness centrality (0.505) - this node is a cross-community bridge._
- **Why does `CatalogPackage` connect `CatalogPackage` to `Equatable`, `PackageNodeID`, `CatalogStore`, `String`, `PackageIconView`, `BreweryCoreTests`, `CatalogSection`, `CatalogSearchResults`, `Foundation`, `CatalogSnapshot`, `CodingKeys`, `ContentView`, `CatalogInstallStatus`?**
  _High betweenness centrality (0.128) - this node is a cross-community bridge._
- **Why does `CodingKeys` connect `CodingKeys` to `Equatable`, `DynamicCodingKey`, `String`?**
  _High betweenness centrality (0.072) - this node is a cross-community bridge._
- **Are the 11 inferred relationships involving `CatalogPackage` (e.g. with `.body` and `.body`) actually correct?**
  _`CatalogPackage` has 11 INFERRED edges - model-reasoned connections that need verification._
- **Are the 4 inferred relationships involving `BrewPackage` (e.g. with `.body` and `.filteredPackages`) actually correct?**
  _`BrewPackage` has 4 INFERRED edges - model-reasoned connections that need verification._
- **What connects `PackageDescription`, `build-app.sh script`, `run-app.sh script` to the rest of the system?**
  _174 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Equatable` be split into smaller, more focused modules?**
  _Cohesion score 0.13709677419354838 - nodes in this community are weakly interconnected._