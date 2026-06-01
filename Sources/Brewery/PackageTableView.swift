import BreweryCore
import SwiftUI

struct PackageTableView: View {
    @EnvironmentObject private var store: PackageStore

    var body: some View {
        Table(store.filteredPackages, selection: $store.selectedPackageID) {
            TableColumn("Name") { package in
                VStack(alignment: .leading, spacing: 2) {
                    Text(package.displayName)
                        .fontWeight(.medium)
                    Text(package.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 3)
            }
            .width(min: 170, ideal: 240)

            TableColumn("Type") { package in
                Text(package.kind.title)
            }
            .width(80)

            TableColumn("Installed") { package in
                Text(package.installedVersion ?? "Unknown")
                    .lineLimit(1)
            }
            .width(min: 110, ideal: 140)

            TableColumn("Current") { package in
                Text(package.currentVersion ?? "Unknown")
                    .lineLimit(1)
            }
            .width(min: 110, ideal: 140)

            TableColumn("Tap") { package in
                Text(package.tap ?? "-")
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .width(min: 130, ideal: 180)

            TableColumn("Status") { package in
                HStack(spacing: 8) {
                    if package.outdated {
                        Label("Outdated", systemImage: "arrow.up.circle.fill")
                            .labelStyle(.iconOnly)
                            .foregroundColor(.orange)
                    }
                    if package.pinned {
                        Label("Pinned", systemImage: "pin.fill")
                            .labelStyle(.iconOnly)
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .width(70)

            TableColumn("Graph") { package in
                HStack(spacing: 8) {
                    Text("\(store.directDependencies(for: package).count) deps")
                    Text("\(store.directDependents(for: package).count) used by")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            }
            .width(min: 130, ideal: 150)
        }
    }
}
