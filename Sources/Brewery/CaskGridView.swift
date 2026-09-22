import BreweryCore
import SwiftUI

/// Installed casks as a grid of cards.
///
/// Casks are apps, and now that each one carries its real icon a grid reads
/// far better than a row of text. Formulae keep the table: they have no icon
/// to anchor a card, and their columns are what matter.
struct CaskGridView: View {
    @EnvironmentObject private var store: PackageStore
    let onAction: (BrewAction) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 230, maximum: 320), spacing: 14, alignment: .top)
    ]

    var body: some View {
        Group {
            if store.filteredPackages.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(store.filteredPackages) { package in
                            InstalledCaskCard(
                                package: package,
                                isSelected: store.selectedPackageID == package.id,
                                dependencyCount: store.directDependencies(for: package).count,
                                dependentCount: store.directDependents(for: package).count,
                                select: { store.selectedPackageID = package.id },
                                action: { onAction($0) }
                            )
                        }
                    }
                    .padding(16)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear(perform: selectFirstCaskIfNeeded)
        .onChange(of: store.filteredPackages) { _ in
            selectFirstCaskIfNeeded()
        }
    }

    /// Arriving here with a formula selected would leave no card highlighted
    /// while the detail pane still described the formula.
    private func selectFirstCaskIfNeeded() {
        let visible = store.filteredPackages
        guard !visible.isEmpty else { return }
        guard !visible.contains(where: { $0.id == store.selectedPackageID }) else { return }
        store.selectedPackageID = visible.first?.id
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "macwindow")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text(store.searchText.isEmpty ? "No casks installed" : "No casks match \"\(store.searchText)\"")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct InstalledCaskCard: View {
    let package: BrewPackage
    let isSelected: Bool
    let dependencyCount: Int
    let dependentCount: Int
    let select: () -> Void
    let action: (BrewAction) -> Void

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

                if package.pinned {
                    Image(systemName: "pin.fill")
                        .foregroundColor(.accentColor)
                        .help("Pinned")
                }
            }

            Text(package.description ?? "No description available")
                .font(.callout)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            // The same two counts the table's Graph column carries.
            Label("\(dependencyCount) deps · \(dependentCount) used by", systemImage: "point.3.connected.trianglepath.dotted")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)

            HStack(spacing: 8) {
                InstalledVersionLabel(package: package)

                Spacer(minLength: 0)

                if package.outdated {
                    Button("Upgrade") {
                        action(.upgrade(name: package.name, kind: package.kind))
                    }
                }
            }
        }
        .padding(14)
        .frame(minHeight: 200, alignment: .topLeading)
        .background(Color(nsColor: .textBackgroundColor))
        .cornerRadius(8)
        .selectionRing(isSelected, cornerRadius: 8)
        .contentShape(Rectangle())
        .onTapGesture(perform: select)
    }
}

/// `installed → current` in orange when an upgrade is waiting, otherwise just
/// the installed version. Shared by the cask card and the formula row so an
/// outdated package looks the same whichever it is.
struct InstalledVersionLabel: View {
    let package: BrewPackage

    var body: some View {
        if package.outdated, let current = package.currentVersion {
            HStack(spacing: 4) {
                Text(package.installedVersion ?? "Unknown")
                    .foregroundColor(.secondary)
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundColor(.orange)
                Text(current)
                    .foregroundColor(.orange)
            }
            .font(.caption)
            .lineLimit(1)
        } else {
            Text(package.installedVersion ?? "Unknown")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
}
