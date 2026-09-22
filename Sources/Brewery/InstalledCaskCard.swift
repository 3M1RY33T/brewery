import BreweryCore
import SwiftUI

/// A card for one installed cask: icon, description, dependency counts,
/// version, and the upgrade and management controls.
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

                PackageManagementMenu(package: package, action: action)
            }
        }
        .padding(14)
        .frame(minHeight: 200, alignment: .topLeading)
        .background(Color.cardBackground)
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
