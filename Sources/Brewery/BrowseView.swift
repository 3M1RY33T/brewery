import BreweryCore
import SwiftUI

/// The catalog, presented as shelves.
///
/// Everything is shown at once rather than filtered by kind: each category is
/// a shelf, casks ride a horizontal row of cards because they are apps with
/// icons, and formulae sit in a list underneath because they are command line
/// tools whose name and description are the whole story.
struct BrowseView: View {
    @ObservedObject var catalogStore: CatalogStore
    let installedPackages: [BrewPackage]
    @Binding var selectedPackage: CatalogPackage?
    let onAction: (BrewAction) -> Void
    let onSelectInstalled: (PackageNodeID) -> Void

    @EnvironmentObject private var pinnedStore: PinnedStore

    /// The chip strip duplicates the category tiles, so it only shows once
    /// the tiles have scrolled out of view, and hides again on the way back.
    @State private var tilesAreOffscreen = false
    /// Showing the pinned list in place of the shelves.
    @State private var isShowingPinned = false
    /// Width inside the page's horizontal padding, for shelves that choose
    /// their column count.
    @State private var contentWidth: CGFloat = 0

    private static let scrollSpace = "browse"

    /// The scroll target for a shelf. Chips and tiles are also built with
    /// `ForEach(sections)`, which gives them the section's id implicitly, so
    /// `scrollTo(section.id)` had three candidates and the chip's own
    /// horizontal scroll view answered first. Only the shelf carries this id.
    private static func shelfID(for sectionID: String) -> String {
        "shelf-" + sectionID
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    if !catalogStore.isSearching && !isShowingPinned && tilesAreOffscreen {
                        categoryStrip(proxy: proxy)
                        Divider()
                    }

                    ScrollView {
                        if catalogStore.isSearching {
                            searchResults
                        } else if isShowingPinned {
                            pinnedResults
                        } else {
                            shelves(proxy: proxy)
                        }
                    }
                    .coordinateSpace(name: Self.scrollSpace)
                }
                .animation(.easeInOut(duration: 0.18), value: tilesAreOffscreen)
            }
        }
        .onPreferenceChange(TileGridFramePreference.self) { frame in
            // LazyVStack stops reporting a child's preference once it leaves
            // the viewport, so nil arrives at the exact moment the tiles
            // scroll away and is the signal, not a gap in it. While
            // searching the grid is absent too, but the strip is gated on
            // that separately.
            tilesAreOffscreen = frame.map { $0.maxY <= 0 } ?? true
            // The measured block carries the page's 16pt side padding.
            if let frame, frame.width > 32 { contentWidth = frame.width - 32 }
        }
        .onChange(of: catalogStore.sections) { _ in
            refreshSelection()
        }
    }

    // MARK: - Chrome

    private var header: some View {
        HStack {
            TextField("Search Homebrew", text: $catalogStore.searchText)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 360)

            if catalogStore.isSearching {
                Button {
                    catalogStore.searchText = ""
                } label: {
                    Label("Clear", systemImage: "xmark.circle.fill")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }

            Spacer()

            if catalogStore.isLoading {
                ProgressView()
                    .controlSize(.small)
            }

            Text(catalogStore.statusMessage)
                .foregroundColor(.secondary)
                .lineLimit(1)

            Button {
                isShowingPinned.toggle()
            } label: {
                HStack(spacing: 5) {
                    Label("Pinned", systemImage: isShowingPinned ? "pin.fill" : "pin")
                    if pinnedStore.count > 0 {
                        Text("\(pinnedStore.count)")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(isShowingPinned ? Color.white.opacity(0.25) : Color.chipBackground)
                            .cornerRadius(5)
                    }
                }
            }
            .buttonStyle(.bordered)
            .tint(isShowingPinned ? .accentColor : nil)
            .help(isShowingPinned ? "Back to the catalog" : "Show the packages you have pinned")

            Button {
                Task { await catalogStore.load(installedPackages: installedPackages, forceRefresh: true) }
            } label: {
                Label("Refresh Catalog", systemImage: "arrow.clockwise")
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    /// Jump links, not filters: every shelf stays on the page.
    private func categoryStrip(proxy: ScrollViewProxy) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(catalogStore.sections.filter { $0.category != .featured }) { section in
                    Button {
                        withAnimation {
                            proxy.scrollTo(Self.shelfID(for: section.id), anchor: .top)
                        }
                    } label: {
                        Label(section.category.title, systemImage: section.category.systemImage)
                            .font(.callout)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.chipBackground)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Shelves

    @ViewBuilder
    private func shelves(proxy: ScrollViewProxy) -> some View {
        let featured = catalogStore.sections.first { $0.category == .featured }
        let subjects = catalogStore.sections.filter { $0.category != .featured }

        LazyVStack(alignment: .leading, spacing: 34) {
            if let featured, !featured.casks.isEmpty {
                // Hero cards bleed to the window edge, so they manage their
                // own horizontal padding rather than inheriting the page's.
                HeroCarousel(
                    packages: Array(featured.casks.prefix(6)),
                    selectedPackage: $selectedPackage,
                    action: handlePrimaryAction
                )
                .padding(.top, 16)
            }

            VStack(alignment: .leading, spacing: 12) {
                ShelfHeader(title: "Categories", systemImage: "square.grid.2x2")
                CategoryTileGrid(sections: subjects, availableWidth: contentWidth) { id in
                    withAnimation { proxy.scrollTo(Self.shelfID(for: id), anchor: .top) }
                }
            }
            .padding(.horizontal, 16)
            .background(
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: TileGridFramePreference.self,
                        value: geometry.frame(in: .named(Self.scrollSpace))
                    )
                }
            )

            if let featured {
                TopChartsShelf(
                    casks: featured.casks,
                    formulae: featured.formulae,
                    availableWidth: contentWidth,
                    selectedPackage: $selectedPackage,
                    action: handlePrimaryAction
                )
                .padding(.horizontal, 16)
            }

            ForEach(subjects) { section in
                CatalogShelf(
                    section: section,
                    selectedPackage: $selectedPackage,
                    action: handlePrimaryAction
                )
                .id(Self.shelfID(for: section.id))
            }
        }
        .padding(.bottom, 24)
    }

    @ViewBuilder
    private var searchResults: some View {
        let results = catalogStore.searchResults

        if results.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("Nothing matches \"\(catalogStore.searchText)\"")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 80)
        } else {
            LazyVStack(alignment: .leading, spacing: 30) {
                if !results.casks.isEmpty {
                    CaskShelfRow(
                        title: "Casks",
                        packages: results.casks,
                        total: results.casks.count,
                        selectedPackage: $selectedPackage,
                        action: handlePrimaryAction
                    )
                }

                if !results.formulae.isEmpty {
                    FormulaShelfList(
                        title: "Formulae",
                        packages: results.formulae,
                        total: results.formulae.count,
                        selectedPackage: $selectedPackage,
                        action: handlePrimaryAction
                    )
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 16)
        }
    }

    /// Everything pinned, casks as cards and formulae as rows, like search.
    @ViewBuilder
    private var pinnedResults: some View {
        let pinned = pinnedStore.pinned(in: catalogStore.packages)
        let casks = pinned.filter { $0.kind == .cask }
        let formulae = pinned.filter { $0.kind == .formula }

        if pinned.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "pin")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("Nothing pinned yet")
                    .font(.headline)
                Text("Use the pin on any entry to keep it here.")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 80)
        } else {
            LazyVStack(alignment: .leading, spacing: 30) {
                ShelfHeader(title: "Pinned", systemImage: "pin.fill", subtitle: "\(pinned.count) packages")
                    .padding(.horizontal, 16)

                if !casks.isEmpty {
                    CaskShelfRow(
                        title: "Casks",
                        packages: casks,
                        total: casks.count,
                        selectedPackage: $selectedPackage,
                        action: handlePrimaryAction
                    )
                }

                if !formulae.isEmpty {
                    FormulaShelfList(
                        title: "Formulae",
                        packages: formulae,
                        total: formulae.count,
                        selectedPackage: $selectedPackage,
                        action: handlePrimaryAction
                    )
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 16)
        }
    }

    // MARK: - Behaviour

    private func handlePrimaryAction(for package: CatalogPackage) {
        switch package.installStatus {
        case .notInstalled:
            onAction(.install(name: package.name, kind: package.kind))
        case .installed(let outdated):
            if outdated {
                onAction(.upgrade(name: package.name, kind: package.kind))
            } else {
                onSelectInstalled(package.nodeID)
            }
        }
    }

    /// The selected package's install state can change under it when the
    /// catalog merges a fresh inventory; swap in the current copy. Nothing is
    /// ever selected on the user's behalf.
    private func refreshSelection() {
        guard let selectedPackage,
              let refreshed = catalogStore.packages.first(where: { $0.id == selectedPackage.id }) else { return }
        self.selectedPackage = refreshed
    }
}

/// Where the category tiles sit relative to the scroll view's visible area.
private struct TileGridFramePreference: PreferenceKey {
    static var defaultValue: CGRect? = nil
    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        value = nextValue() ?? value
    }
}

// MARK: - Shelf

private struct CatalogShelf: View {
    let section: CatalogSection
    @Binding var selectedPackage: CatalogPackage?
    let action: (CatalogPackage) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ShelfHeader(
                title: section.category.title,
                systemImage: section.category.systemImage,
                subtitle: subtitle
            )
            .padding(.horizontal, 16)

            casks

            if !section.formulae.isEmpty {
                FormulaShelfList(
                    title: "\(section.category.title) Formulae",
                    packages: section.formulae,
                    total: section.formulaTotal,
                    columns: section.category.shelfStyle == .compactGrid ? 2 : 1,
                    selectedPackage: $selectedPackage,
                    action: action
                )
                .padding(.horizontal, 16)
            }
        }
    }

    private var subtitle: String? {
        let total = section.caskTotal + section.formulaTotal
        guard total > 0 else { return nil }
        return "\(total.formatted()) packages"
    }

    /// Each style exists because the shelf underneath it is shaped
    /// differently: a handful worth showing off, a spotlight worth leading
    /// with, or hundreds worth scanning.
    @ViewBuilder
    private var casks: some View {
        if section.casks.isEmpty {
            EmptyView()
        } else {
            switch section.category.shelfStyle {
            case .showcase:
                CaskShelfRow(
                    title: "\(section.category.title) Casks",
                    packages: section.casks,
                    total: section.caskTotal,
                    selectedPackage: $selectedPackage,
                    action: action
                )
            case .compactGrid:
                VStack(alignment: .leading, spacing: 8) {
                    ShelfSubheading(title: "\(section.category.title) Casks", shown: section.casks.count, total: section.caskTotal)
                        .padding(.horizontal, 16)
                    CompactIconGrid(
                        packages: section.casks,
                        selectedPackage: $selectedPackage,
                        action: action
                    )
                }
            case .spotlight:
                VStack(alignment: .leading, spacing: 8) {
                    ShelfSubheading(title: "\(section.category.title) Casks", shown: section.casks.count, total: section.caskTotal)
                    SpotlightShelf(
                        packages: section.casks,
                        tintHue: section.category.tintHue,
                        selectedPackage: $selectedPackage,
                        action: action
                    )
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

/// Casks: a single horizontal row of cards, scrolled sideways.
private struct CaskShelfRow: View {
    let title: String
    let packages: [CatalogPackage]
    let total: Int
    @Binding var selectedPackage: CatalogPackage?
    let action: (CatalogPackage) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ShelfSubheading(title: title, shown: packages.count, total: total)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(packages) { package in
                        CatalogCard(
                            package: package,
                            isSelected: selectedPackage?.id == package.id,
                            open: { selectedPackage = package },
                            action: { action(package) }
                        )
                        .frame(width: 240)
                    }
                }
                .padding(.vertical, 2)
                .padding(.horizontal, 16)
            }
        }
    }
}

/// Formulae: a list, because a card of an icon-less CLI tool says nothing a
/// row does not say more compactly.
private struct FormulaShelfList: View {
    let title: String
    let packages: [CatalogPackage]
    let total: Int
    var columns = 1
    @Binding var selectedPackage: CatalogPackage?
    let action: (CatalogPackage) -> Void

    private var split: [[CatalogPackage]] {
        guard columns > 1 else { return [packages] }
        let perColumn = Int((Double(packages.count) / Double(columns)).rounded(.up))
        guard perColumn > 0 else { return [packages] }
        return stride(from: 0, to: packages.count, by: perColumn).map {
            Array(packages[$0..<min($0 + perColumn, packages.count)])
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ShelfSubheading(title: title, shown: packages.count, total: total)

            HStack(alignment: .top, spacing: 12) {
                ForEach(Array(split.enumerated()), id: \.offset) { _, column in
                    VStack(spacing: 0) {
                        ForEach(Array(column.enumerated()), id: \.element.id) { index, package in
                            if index > 0 {
                                Divider()
                            }
                            FormulaRow(
                                package: package,
                                isSelected: selectedPackage?.id == package.id,
                                open: { selectedPackage = package },
                                action: { action(package) }
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.cardBackground)
                    .cornerRadius(8)
                }
            }
        }
    }
}

private struct ShelfSubheading: View {
    let title: String
    let shown: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.headline)
            if total > shown {
                Text("\(shown) of \(total)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private struct FormulaRow: View {
    let package: CatalogPackage
    let isSelected: Bool
    let open: () -> Void
    let action: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            PinButton(package: package)

            PackageIconView(package: package, size: 26, cornerRadius: 6)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(package.displayName)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Text(package.version ?? "Unknown")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Text(package.description ?? "No description available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Button(package.installStatus.title, action: action)
                .disabled(package.installStatus == .installed(outdated: false))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .selectionFill(isSelected)
        .contentShape(Rectangle())
        .onTapGesture(perform: open)
    }
}

private struct CatalogCard: View {
    let package: CatalogPackage
    let isSelected: Bool
    let open: () -> Void
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                PackageIconView(package: package, size: 46)

                VStack(alignment: .leading, spacing: 3) {
                    Text(package.displayName)
                        .font(.headline)
                        .lineLimit(2)
                    Text(package.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                PinButton(package: package)
            }

            Text(package.description ?? "No description available")
                .font(.callout)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            HStack {
                Text(package.version ?? "Unknown")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Spacer()

                Button(package.installStatus.title, action: action)
                    .disabled(package.installStatus == .installed(outdated: false))
            }
        }
        .padding(14)
        .frame(minHeight: 190, alignment: .topLeading)
        .background(Color.cardBackground)
        .cornerRadius(8)
        .selectionRing(isSelected, cornerRadius: 8)
        .contentShape(Rectangle())
        .onTapGesture(perform: open)
    }
}

struct CatalogPackageDetailView: View {
    let package: CatalogPackage?
    /// Under the content rather than beside it: wide and short, so the
    /// facts sit beside the header instead of below it.
    var isStacked = false
    let action: (BrewAction) -> Void
    let onSelectInstalled: (PackageNodeID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let package {
                ScrollView {
                    Group {
                        if isStacked {
                            HStack(alignment: .top, spacing: 28) {
                                VStack(alignment: .leading, spacing: 16) {
                                    heading(for: package)
                                    actions(for: package)
                                }
                                .frame(maxWidth: .infinity, alignment: .topLeading)

                                VStack(alignment: .leading, spacing: 16) {
                                    facts(for: package)
                                }
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 16) {
                                heading(for: package)
                                actions(for: package)
                                facts(for: package)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "square.grid.2x2")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Select a package")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func heading(for package: CatalogPackage) -> some View {
                        HStack(alignment: .top, spacing: 14) {
                            PackageIconView(package: package, size: 72, cornerRadius: 12)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(package.displayName)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(package.name)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(package.description ?? "No description available")
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
    }

    private func actions(for package: CatalogPackage) -> some View {
        HStack {
            Button {
                handlePrimaryAction(for: package)
            } label: {
                Text(package.installStatus.title)
            }
                .disabled(package.installStatus == .installed(outdated: false))

            DetailPinButton(package: package)

            if package.installStatus != .notInstalled {
                Button {
                    onSelectInstalled(package.nodeID)
                } label: {
                    Label("Open Installed", systemImage: "arrow.right.circle")
                }
            }
        }
    }

    @ViewBuilder
    private func facts(for package: CatalogPackage) -> some View {
        DetailRow(label: "Type", value: package.kind.title)
        DetailRow(label: "Version", value: package.version ?? "Unknown")
        DetailRow(label: "Tap", value: package.tap ?? "Unknown")

        if let homepage = package.homepage {
            Link(destination: homepage) {
                Label(homepage.absoluteString, systemImage: "link")
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }

        if !package.dependencies.isEmpty {
            DetailBlock(label: "Dependencies", text: package.dependencies.prefix(24).joined(separator: ", "))
        }
    }

    private func handlePrimaryAction(for package: CatalogPackage) {
        switch package.installStatus {
        case .notInstalled:
            action(.install(name: package.name, kind: package.kind))
        case .installed(let outdated):
            if outdated {
                action(.upgrade(name: package.name, kind: package.kind))
            } else {
                onSelectInstalled(package.nodeID)
            }
        }
    }
}


/// The pin as a labelled button, for the detail pane where there is room.
private struct DetailPinButton: View {
    @EnvironmentObject private var pinnedStore: PinnedStore
    let package: CatalogPackage

    var body: some View {
        let isPinned = pinnedStore.isPinned(package.id)
        Button {
            pinnedStore.toggle(package.id)
        } label: {
            Label(isPinned ? "Unpin" : "Pin", systemImage: isPinned ? "pin.fill" : "pin")
        }
    }
}
