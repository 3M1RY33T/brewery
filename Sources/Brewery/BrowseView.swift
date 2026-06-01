import BreweryCore
import SwiftUI

struct BrowseView: View {
    @ObservedObject var catalogStore: CatalogStore
    let installedPackages: [BrewPackage]
    @Binding var selectedPackage: CatalogPackage?
    let onAction: (BrewAction) -> Void
    let onSelectInstalled: (PackageNodeID) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 230, maximum: 320), spacing: 14, alignment: .top)
    ]

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    categoryStrip

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(catalogStore.filteredPackages.prefix(500)) { package in
                            CatalogCard(package: package) {
                                selectedPackage = package
                            } action: {
                                handlePrimaryAction(for: package)
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .onChange(of: catalogStore.filteredPackages) { packages in
            guard let selectedPackage else {
                self.selectedPackage = packages.first
                return
            }

            if let refreshedSelection = packages.first(where: { $0.id == selectedPackage.id }) {
                self.selectedPackage = refreshedSelection
            } else {
                self.selectedPackage = packages.first
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                TextField("Search Homebrew", text: $catalogStore.searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 360)

                Picker("Type", selection: $catalogStore.kindFilter) {
                    ForEach(CatalogKindFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 260)

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
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var categoryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CatalogCategory.available(for: catalogStore.kindFilter)) { category in
                    Button {
                        catalogStore.category = category
                    } label: {
                        Label(category.title, systemImage: icon(for: category))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(catalogStore.category == category ? Color.accentColor.opacity(0.18) : Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onChange(of: catalogStore.kindFilter) { _ in
            catalogStore.normalizeCategory()
        }
    }

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

    private func icon(for category: CatalogCategory) -> String {
        switch category {
        case .featured: return "sparkles"
        case .guiApps: return "macwindow"
        case .developerTools: return "hammer"
        case .media: return "play.rectangle"
        case .productivity: return "checklist"
        case .cliTools: return "terminal"
        case .libraries: return "books.vertical"
        case .utilities: return "wrench.and.screwdriver"
        }
    }
}

private struct CatalogCard: View {
    let package: CatalogPackage
    let open: () -> Void
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: open) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(package.kind == .cask ? Color.blue.opacity(0.16) : Color.green.opacity(0.16))
                            Image(systemName: package.kind == .cask ? "macwindow" : "terminal")
                                .font(.title2)
                                .foregroundColor(package.kind == .cask ? .blue : .green)
                        }
                        .frame(width: 46, height: 46)

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
                }
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            HStack {
                Text(package.kind.title)
                    .font(.caption)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)

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
        .frame(minHeight: 180, alignment: .topLeading)
        .background(Color(nsColor: .textBackgroundColor))
        .cornerRadius(8)
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
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(package.kind == .cask ? Color.blue.opacity(0.16) : Color.green.opacity(0.16))
                                Image(systemName: package.kind == .cask ? "macwindow" : "terminal")
                                    .font(.largeTitle)
                                    .foregroundColor(package.kind == .cask ? .blue : .green)
                            }
                            .frame(width: 72, height: 72)

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
