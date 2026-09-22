import BreweryCore
import SwiftUI

struct PackageDetailView: View {
    @EnvironmentObject private var store: PackageStore

    let package: BrewPackage?
    /// Under the content rather than beside it: wide and short, so the
    /// sections sit in two columns instead of one long scroll.
    var isStacked = false
    let onSelectPackage: (PackageNodeID) -> Void
    let onAction: (BrewAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let package {
                ScrollView {
                    Group {
                        if isStacked {
                            HStack(alignment: .top, spacing: 28) {
                                VStack(alignment: .leading, spacing: 16) {
                                    header(for: package)
                                    actions(for: package)
                                }
                                .frame(maxWidth: .infinity, alignment: .topLeading)

                                VStack(alignment: .leading, spacing: 16) {
                                    metadata(for: package)
                                }
                                .frame(maxWidth: .infinity, alignment: .topLeading)

                                graphSections(for: package)
                                    .frame(maxWidth: .infinity, alignment: .topLeading)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 16) {
                                header(for: package)
                                actions(for: package)
                                metadata(for: package)
                                graphSections(for: package)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "shippingbox")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No package selected")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func header(for package: BrewPackage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                PackageIconView(package: package, size: 56, cornerRadius: 10)

                VStack(alignment: .leading, spacing: 4) {
                    Text(package.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)

                    Text(package.name)
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
            }

            if let description = package.description {
                Text(description)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                Text(package.kind.title)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.12))
                    .cornerRadius(6)

                if package.outdated {
                    Text("Outdated")
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                if package.pinned {
                    Text("Pinned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func actions(for package: BrewPackage) -> some View {
        HStack {
            Button {
                onAction(.upgrade(name: package.name, kind: package.kind))
            } label: {
                Label("Upgrade", systemImage: "arrow.up.circle")
            }
            .disabled(!package.outdated)

            Button(role: .destructive) {
                onAction(.uninstall(name: package.name, kind: package.kind))
            } label: {
                Label("Uninstall", systemImage: "trash")
            }
        }
    }

    private func metadata(for package: BrewPackage) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            DetailRow(label: "Installed", value: package.installedVersion ?? "Unknown")
            DetailRow(label: "Current", value: package.currentVersion ?? "Unknown")
            DetailRow(label: "Tap", value: package.tap ?? "-")

            if let homepage = package.homepage {
                Link(destination: homepage) {
                    Label(homepage.absoluteString, systemImage: "link")
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !package.dependencies.isEmpty {
                DetailBlock(label: "Declared Dependencies", text: package.dependencies.joined(separator: ", "))
            }

            if !package.installedPaths.isEmpty {
                DetailBlock(label: "Installed Paths", text: package.installedPaths.joined(separator: "\n"))
            }

            if let caveats = package.caveats, !caveats.isEmpty {
                DetailBlock(label: "Caveats", text: caveats)
            }
        }
    }

    private func graphSections(for package: BrewPackage) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            DependencyNodeList(
                title: "Dependencies",
                nodes: store.directDependencies(for: package),
                store: store,
                onSelectPackage: onSelectPackage
            )

            DependencyNodeList(
                title: "Dependents",
                nodes: store.directDependents(for: package),
                store: store,
                onSelectPackage: onSelectPackage
            )
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
    }
}

struct DetailBlock: View {
    let label: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(text)
                .font(.callout)
                .textSelection(.enabled)
                .lineLimit(8)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct DependencyNodeList: View {
    let title: String
    let nodes: [PackageNodeID]
    let store: PackageStore
    let onSelectPackage: (PackageNodeID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(title) (\(nodes.count))")
                .font(.headline)

            if nodes.isEmpty {
                Text("None")
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(nodes) { node in
                        if let package = store.package(for: node) {
                            Button {
                                onSelectPackage(node)
                            } label: {
                                HStack {
                                    Image(systemName: package.kind == .formula ? "terminal" : "macwindow")
                                    Text(package.displayName)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    Spacer()
                                    Text(package.kind.title)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        } else {
                            HStack {
                                Image(systemName: node.kind == .formula ? "terminal" : "macwindow")
                                Text(node.name)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                Text("Not installed")
                                    .foregroundColor(.secondary)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
}
