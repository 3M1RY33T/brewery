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

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    if !catalogStore.isSearching {
                        categoryStrip(proxy: proxy)
                        Divider()
                    }

                    ScrollView {
                        if catalogStore.isSearching {
                            searchResults
                        } else {
                            shelves
                        }
                    }
                }
            }
        }
        .onChange(of: catalogStore.sections) { _ in
            selectDefaultPackageIfNeeded()
        }
        .onChange(of: catalogStore.searchText) { _ in
            selectDefaultPackageIfNeeded()
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
                ForEach(catalogStore.sections) { section in
                    Button {
                        withAnimation {
                            proxy.scrollTo(section.id, anchor: .top)
                        }
                    } label: {
                        Label(section.category.title, systemImage: section.category.systemImage)
                            .font(.callout)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color(nsColor: .controlBackgroundColor))
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

    private var shelves: some View {
        LazyVStack(alignment: .leading, spacing: 30) {
            ForEach(catalogStore.sections) { section in
                CatalogShelf(
                    section: section,
                    selectedPackage: $selectedPackage,
                    action: handlePrimaryAction
                )
                .id(section.id)
            }
        }
        .padding(16)
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
                }
            }
            .padding(16)
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

    /// Keeps the detail pane pointed at something that is actually on screen.
    private func selectDefaultPackageIfNeeded() {
        let visible: [CatalogPackage]
        if catalogStore.isSearching {
            let results = catalogStore.searchResults
            visible = results.casks + results.formulae
        } else {
            visible = catalogStore.sections.flatMap { $0.casks + $0.formulae }
        }

        guard !visible.isEmpty else { return }
        if let selectedPackage, let refreshed = visible.first(where: { $0.id == selectedPackage.id }) {
            self.selectedPackage = refreshed
            return
        }
        selectedPackage = visible.first
    }
}

// MARK: - Shelf

private struct CatalogShelf: View {
    let section: CatalogSection
    @Binding var selectedPackage: CatalogPackage?
    let action: (CatalogPackage) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(section.category.title, systemImage: section.category.systemImage)
                .font(.title2.weight(.semibold))

            if !section.casks.isEmpty {
                CaskShelfRow(
                    title: "Casks",
                    packages: section.casks,
                    total: section.caskTotal,
                    selectedPackage: $selectedPackage,
                    action: action
                )
            }

            if !section.formulae.isEmpty {
                FormulaShelfList(
                    title: "Formulae",
                    packages: section.formulae,
                    total: section.formulaTotal,
                    selectedPackage: $selectedPackage,
                    action: action
                )
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
    @Binding var selectedPackage: CatalogPackage?
    let action: (CatalogPackage) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ShelfSubheading(title: title, shown: packages.count, total: total)

            VStack(spacing: 0) {
                ForEach(Array(packages.enumerated()), id: \.element.id) { index, package in
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
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(8)
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
        .background(isSelected ? Color.accentColor.opacity(0.14) : Color.clear)
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
        .background(Color(nsColor: .textBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: open)
    }
}

struct CatalogPackageDetailView: View {
    let package: CatalogPackage?
    let action: (BrewAction) -> Void
    let onSelectInstalled: (PackageNodeID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let package {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
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

                        HStack {
                            Button {
                                handlePrimaryAction(for: package)
                            } label: {
                                Text(package.installStatus.title)
                            }
                                .disabled(package.installStatus == .installed(outdated: false))

                            if package.installStatus != .notInstalled {
                                Button {
                                    onSelectInstalled(package.nodeID)
                                } label: {
                                    Label("Open Installed", systemImage: "arrow.right.circle")
                                }
                            }
                        }

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
