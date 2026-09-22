import BreweryCore
import SwiftUI

/// Outdated packages, split by kind the way Browse is: casks as cards,
/// formulae as rows. Both are things you upgrade, but a cask has an icon and
/// a name people recognise, while a formula is its token and its versions.
struct OutdatedView: View {
    @EnvironmentObject private var store: PackageStore
    let onAction: (BrewAction) -> Void

    @State private var isShowingAllCasks = false
    /// An upgrade requested from inside the popup. The confirmation is a
    /// sheet on the same window, and macOS will not stack one sheet on
    /// another, so it waits until the popup has gone.
    @State private var queuedAction: BrewAction?

    private var casks: [BrewPackage] { store.filteredPackages.filter { $0.kind == .cask } }
    private var formulae: [BrewPackage] { store.filteredPackages.filter { $0.kind == .formula } }

    var body: some View {
        Group {
            if store.filteredPackages.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 28) {
                        if !casks.isEmpty {
                            section(title: "Casks", systemImage: "macwindow", count: casks.count, accessory: {
                                HStack(spacing: 14) {
                                    Button {
                                        isShowingAllCasks = true
                                    } label: {
                                        Label("Show All", systemImage: "square.grid.2x2")
                                            .font(.callout.weight(.medium))
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundColor(.accentColor)

                                    upgradeAllButton(for: casks, kind: .cask)
                                }
                            }) {
                                caskRow
                            }
                        }

                        if !formulae.isEmpty {
                            section(title: "Formulae", systemImage: "terminal", count: formulae.count, accessory: {
                                upgradeAllButton(for: formulae, kind: .formula)
                            }) {
                                VStack(spacing: 0) {
                                    ForEach(Array(formulae.enumerated()), id: \.element.id) { index, package in
                                        if index > 0 { Divider() }
                                        OutdatedFormulaRow(
                                            package: package,
                                            isSelected: store.selectedPackageID == package.id,
                                            dependencyCount: store.directDependencies(for: package).count,
                                            dependentCount: store.directDependents(for: package).count,
                                            select: { store.selectedPackageID = package.id },
                                            action: onAction
                                        )
                                    }
                                }
                                .background(Color(nsColor: .textBackgroundColor))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear(perform: selectFirstIfNeeded)
        .onChange(of: store.filteredPackages) { _ in
            selectFirstIfNeeded()
        }
        .sheet(isPresented: $isShowingAllCasks, onDismiss: flushQueuedAction) {
            OutdatedCasksSheet(casks: casks) { action in
                queuedAction = action
                isShowingAllCasks = false
            }
        }
    }

    /// One row of cards, scrolled sideways. The popup has the full grid.
    private var caskRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(casks) { package in
                    InstalledCaskCard(
                        package: package,
                        isSelected: store.selectedPackageID == package.id,
                        dependencyCount: store.directDependencies(for: package).count,
                        dependentCount: store.directDependents(for: package).count,
                        select: { store.selectedPackageID = package.id },
                        action: onAction
                    )
                    .frame(width: 240)
                }
            }
            .padding(.vertical, 2)
        }
    }

    /// Upgrades exactly the packages listed in this section. With a search
    /// active that is the filtered set, which is what "all" means on screen.
    private func upgradeAllButton(for packages: [BrewPackage], kind: PackageKind) -> some View {
        Button {
            onAction(.upgradeAll(names: packages.map(\.name), kind: kind))
        } label: {
            Label("Upgrade All", systemImage: "arrow.up.circle")
        }
        .disabled(store.isRunningCommand)
        .help("Run brew upgrade for every \(kind == .cask ? "cask" : "formula") listed here")
    }

    private func flushQueuedAction() {
        guard let action = queuedAction else { return }
        queuedAction = nil
        onAction(action)
    }

    private func section<Accessory: View, Content: View>(
        title: String,
        systemImage: String,
        count: Int,
        @ViewBuilder accessory: () -> Accessory,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Label(title, systemImage: systemImage)
                    .font(.title3.weight(.semibold))
                Text("\(count)")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)

                Spacer(minLength: 8)

                accessory()
            }
            content()
        }
    }

    /// Keeps the detail pane on something that is actually in this view.
    private func selectFirstIfNeeded() {
        let visible = store.filteredPackages
        guard !visible.isEmpty else { return }
        guard !visible.contains(where: { $0.id == store.selectedPackageID }) else { return }
        store.selectedPackageID = visible.first?.id
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text(store.searchText.isEmpty ? "Everything is up to date" : "No outdated packages match \"\(store.searchText)\"")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// One outdated formula: what it is, what it will become, and who depends on it.
private struct OutdatedFormulaRow: View {
    let package: BrewPackage
    let isSelected: Bool
    let dependencyCount: Int
    let dependentCount: Int
    let select: () -> Void
    let action: (BrewAction) -> Void

    var body: some View {
        HStack(spacing: 12) {
            PackageIconView(package: package, size: 30, cornerRadius: 7)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(package.displayName)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    if package.pinned {
                        Image(systemName: "pin.fill")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                            .help("Pinned")
                    }
                }
                Text(package.description ?? package.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            // Dependents matter most here: upgrading this changes what they run against.
            Text("\(dependencyCount) deps · \(dependentCount) used by")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(minWidth: 120, alignment: .trailing)

            InstalledVersionLabel(package: package)
                .frame(minWidth: 150, alignment: .trailing)

            Button("Upgrade") {
                action(.upgrade(name: package.name, kind: package.kind))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .selectionFill(isSelected)
        .contentShape(Rectangle())
        .onTapGesture(perform: select)
    }
}


/// Every outdated cask at once, as the grid the Casks page uses.
private struct OutdatedCasksSheet: View {
    @EnvironmentObject private var store: PackageStore
    @Environment(\.dismiss) private var dismiss
    let casks: [BrewPackage]
    /// Upgrades go back to the owner, which closes this sheet before the
    /// confirmation can be shown.
    let action: (BrewAction) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 230, maximum: 320), spacing: 14, alignment: .top)
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Label("Outdated Casks", systemImage: "macwindow")
                    .font(.title3.weight(.semibold))
                Text("\(casks.count)")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)

                Spacer()

                Button("Done") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(16)

            Divider()

            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(casks) { package in
                        InstalledCaskCard(
                            package: package,
                            isSelected: store.selectedPackageID == package.id,
                            dependencyCount: store.directDependencies(for: package).count,
                            dependentCount: store.directDependents(for: package).count,
                            select: { store.selectedPackageID = package.id },
                            action: action
                        )
                    }
                }
                .padding(16)
            }
        }
        .frame(minWidth: 780, idealWidth: 920, maxWidth: 1200, minHeight: 480, idealHeight: 640, maxHeight: 900)
    }
}
