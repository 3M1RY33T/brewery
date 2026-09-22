import BreweryCore
import SwiftUI

/// Installed packages split by kind the way Browse is: casks as a card row
/// with a popup for the full grid, formulae as rows. Library shows everything
/// installed; Outdated shows the subset with an upgrade waiting. Both are
/// places to manage packages, so every card and row can upgrade or uninstall.
struct InstalledPackagesView: View {
    @EnvironmentObject private var store: PackageStore
    let onAction: (BrewAction) -> Void
    /// What to say when the list is empty, with and without a search.
    let emptyTitle: String
    let emptySearchTitle: (String) -> String
    let emptySymbol: String

    @State private var isShowingAllCasks = false
    /// An action requested from inside the popup. The confirmation is a
    /// sheet on the same window, and macOS will not stack one sheet on
    /// another, so it waits until the popup has gone.
    @State private var queuedAction: BrewAction?

    // Anything needing attention leads. On Outdated that is everything, so
    // the order is unchanged there; in the Library it floats upgrades to the top.
    private var casks: [BrewPackage] { store.filteredPackages.filter { $0.kind == .cask }.outdatedFirst() }
    private var formulae: [BrewPackage] { store.filteredPackages.filter { $0.kind == .formula }.outdatedFirst() }

    static func outdated(onAction: @escaping (BrewAction) -> Void) -> InstalledPackagesView {
        InstalledPackagesView(
            onAction: onAction,
            emptyTitle: "Everything is up to date",
            emptySearchTitle: { "No outdated packages match \"\($0)\"" },
            emptySymbol: "checkmark.circle"
        )
    }

    static func library(onAction: @escaping (BrewAction) -> Void) -> InstalledPackagesView {
        InstalledPackagesView(
            onAction: onAction,
            emptyTitle: "Nothing installed yet",
            emptySearchTitle: { "No installed packages match \"\($0)\"" },
            emptySymbol: "books.vertical"
        )
    }

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
                                        InstalledFormulaRow(
                                            package: package,
                                            isSelected: store.selectedPackageID == package.id,
                                            dependencyCount: store.directDependencies(for: package).count,
                                            dependentCount: store.directDependents(for: package).count,
                                            select: { store.selectedPackageID = package.id },
                                            action: onAction
                                        )
                                    }
                                }
                                .background(Color.cardBackground)
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
            InstalledCasksSheet(casks: casks) { action in
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

    /// Upgrades the packages in this section that have an upgrade waiting.
    /// On Outdated that is every one listed; in the Library it is the
    /// subset, and the button says how many. With a search active it is the
    /// filtered set, which is what "all" means on screen.
    private func upgradeAllButton(for packages: [BrewPackage], kind: PackageKind) -> some View {
        let outdated = packages.filter(\.outdated)
        let everyListedIsOutdated = outdated.count == packages.count
        return Button {
            onAction(.upgradeAll(names: outdated.map(\.name), kind: kind))
        } label: {
            Label(
                everyListedIsOutdated ? "Upgrade All" : "Upgrade \(outdated.count) Outdated",
                systemImage: "arrow.up.circle"
            )
        }
        .disabled(store.isRunningCommand || outdated.isEmpty)
        .help(outdated.isEmpty
              ? "Every \(kind == .cask ? "cask" : "formula") listed here is up to date"
              : "Run brew upgrade for the outdated \(kind == .cask ? "casks" : "formulae") listed here")
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
                    .background(Color.chipBackground)
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
            Image(systemName: emptySymbol)
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text(store.searchText.isEmpty ? emptyTitle : emptySearchTitle(store.searchText))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Upgrade, when there is one, and uninstall, always. The upgrade also has
/// its own button beside the version so the common action is one click; the
/// menu is where the destructive one lives, behind a deliberate second step
/// before the confirmation sheet adds a third.
struct PackageManagementMenu: View {
    let package: BrewPackage
    let action: (BrewAction) -> Void

    var body: some View {
        Menu {
            if package.outdated {
                Button {
                    action(.upgrade(name: package.name, kind: package.kind))
                } label: {
                    Label("Upgrade", systemImage: "arrow.up.circle")
                }
            }
            Button(role: .destructive) {
                action(.uninstall(name: package.name, kind: package.kind))
            } label: {
                Label("Uninstall", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 15))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Manage \(package.displayName)")
    }
}

/// One installed formula: what it is, its versions, and who depends on it.
private struct InstalledFormulaRow: View {
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

            // Dependents matter most here: changing this changes what they run against.
            Text("\(dependencyCount) deps · \(dependentCount) used by")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(minWidth: 120, alignment: .trailing)

            InstalledVersionLabel(package: package)
                .frame(minWidth: 150, alignment: .trailing)

            if package.outdated {
                Button("Upgrade") {
                    action(.upgrade(name: package.name, kind: package.kind))
                }
            }

            PackageManagementMenu(package: package, action: action)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .selectionFill(isSelected)
        .contentShape(Rectangle())
        .onTapGesture(perform: select)
    }
}

/// Every cask in the section at once, as the grid the Casks page uses.
private struct InstalledCasksSheet: View {
    @EnvironmentObject private var store: PackageStore
    @Environment(\.dismiss) private var dismiss
    let casks: [BrewPackage]
    /// Actions go back to the owner, which closes this sheet before the
    /// confirmation can be shown.
    let action: (BrewAction) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 230, maximum: 320), spacing: 14, alignment: .top)
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Label("Casks", systemImage: "macwindow")
                    .font(.title3.weight(.semibold))
                Text("\(casks.count)")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color.chipBackground)
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
