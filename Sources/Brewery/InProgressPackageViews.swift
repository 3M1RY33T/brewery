import BreweryCore
import SwiftUI

// MARK: - Shared pieces

/// The icon for a package in a live run: the installed package's icon, then
/// the catalog's, then the kind glyph. Shared by the popover row and the
/// Library's in-progress entries so a package looks the same in both.
struct DownloadIcon: View {
    @EnvironmentObject private var store: PackageStore

    let item: DownloadItem
    var catalogStore: CatalogStore?
    var size: CGFloat = 28
    var cornerRadius: CGFloat = 7

    var body: some View {
        if let installed = installedPackage {
            PackageIconView(package: installed, size: size, cornerRadius: cornerRadius)
        } else if let catalog = catalogPackage {
            PackageIconView(package: catalog, size: size, cornerRadius: cornerRadius)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(glyphColor.opacity(0.16))
                Image(systemName: glyph)
                    .font(.system(size: size * 0.42, weight: .medium))
                    .foregroundColor(glyphColor)
            }
            .frame(width: size, height: size)
        }
    }

    private var installedPackage: BrewPackage? {
        store.packages.first { $0.name == item.name && $0.kind == item.kind }
    }

    private var catalogPackage: CatalogPackage? {
        catalogStore?.packages.first { $0.name == item.name && $0.kind == item.kind }
    }

    private var glyph: String {
        switch item.kind {
        case .cask: return "macwindow"
        case .formula: return "terminal"
        case nil: return "arrow.down.circle"
        }
    }

    private var glyphColor: Color {
        item.kind == .cask ? .blue : .green
    }
}

/// The name and description an in-progress entry borrows from the package it
/// will become, so it reads as that package rather than a bare slug.
struct InProgressMetadata {
    let displayName: String
    let description: String?

    init(item: DownloadItem, installed: BrewPackage?, catalog: CatalogPackage?) {
        displayName = installed?.displayName ?? catalog?.displayName ?? item.name
        let resolved = installed?.description ?? catalog?.description
        description = (resolved?.isEmpty == false) ? resolved : nil
    }

    func subtitle(for phase: DownloadPhase) -> String {
        if let description { return description }
        return phase == .queued ? "Waiting for the current command" : "Fetching package details"
    }
}

/// One item's fill, phase-driven when Homebrew gave no percentage, so it
/// always advances. A phase-only bar breathes instead of pretending to be a
/// reading.
struct DownloadProgressBar: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let item: DownloadItem
    var height: CGFloat = 4

    @State private var isPulsing = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.10))

                Capsule()
                    .fill(barColor)
                    .frame(width: barWidth(in: geometry.size.width))
                    .opacity(barOpacity)
            }
        }
        .frame(height: height)
        .onAppear(perform: startPulseIfNeeded)
        .onChange(of: item.fraction) { _ in
            startPulseIfNeeded()
        }
    }

    private var barColor: Color {
        switch item.phase {
        case .failed: return .red.opacity(0.8)
        case .finished: return .green.opacity(0.8)
        case .skipped: return .secondary.opacity(0.5)
        default: return .accentColor
        }
    }

    private var barOpacity: Double {
        guard item.phase.isActive, item.fraction == nil, !reduceMotion else { return 1 }
        return isPulsing ? 0.45 : 1
    }

    private func barWidth(in available: CGFloat) -> CGFloat {
        guard item.phase != .queued else { return 0 }
        return max(3, available * item.progress)
    }

    private func startPulseIfNeeded() {
        guard !reduceMotion, item.phase.isActive, item.fraction == nil, !isPulsing else { return }
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
            isPulsing = true
        }
    }
}

// MARK: - In-category entries

/// A cask being installed, drawn as the card it will become once it lands:
/// same size and layout as `InstalledCaskCard`, dimmed, with its progress
/// across the bottom. It carries no controls — there is nothing to manage
/// until the install finishes.
struct InProgressCaskCard: View {
    @EnvironmentObject private var store: PackageStore

    let item: DownloadItem
    var catalogStore: CatalogStore?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                DownloadIcon(item: item, catalogStore: catalogStore, size: 46)
                    .saturation(0)

                VStack(alignment: .leading, spacing: 3) {
                    Text(metadata.displayName)
                        .font(.headline)
                        .lineLimit(2)
                    Text(item.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: phaseGlyph)
                    .foregroundColor(.accentColor)
                    .help(item.statusText)
            }

            Text(metadata.subtitle(for: item.phase))
                .font(.callout)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            Text(item.statusText)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .opacity(0.55)
        .padding(.top, 14)
        .padding(.horizontal, 14)
        .padding(.bottom, 28)
        .frame(minHeight: 200, alignment: .topLeading)
        .background(dimmedBackground)
        .cornerRadius(8)
        .cardEdge(cornerRadius: 8)
        .overlay(alignment: .bottom) {
            DownloadProgressBar(item: item, height: 5)
                .padding(.horizontal, 14)
                .padding(.bottom, 11)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(metadata.displayName), \(item.statusText)")
    }

    private var metadata: InProgressMetadata {
        InProgressMetadata(
            item: item,
            installed: store.packages.first { $0.name == item.name && $0.kind == item.kind },
            catalog: catalogStore?.packages.first { $0.name == item.name && $0.kind == item.kind }
        )
    }

    private var phaseGlyph: String {
        item.phase == .queued ? "clock" : "arrow.down.circle"
    }

    /// The card surface, darkened, so the entry reads as not yet real without
    /// borrowing the selection or hover treatments a live card has.
    private var dimmedBackground: some View {
        ZStack {
            Color.cardBackground
            Color.black.opacity(0.28)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// A formula being installed, drawn as the row it will become: same layout as
/// `InstalledFormulaRow`, dimmed, with its progress underneath.
struct InProgressFormulaRow: View {
    @EnvironmentObject private var store: PackageStore

    let item: DownloadItem
    var catalogStore: CatalogStore?

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                DownloadIcon(item: item, catalogStore: catalogStore, size: 30)
                    .saturation(0)

                VStack(alignment: .leading, spacing: 2) {
                    Text(metadata.displayName)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Text(metadata.subtitle(for: item.phase))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Text(item.statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .frame(minWidth: 120, alignment: .trailing)
            }
            .opacity(0.55)

            DownloadProgressBar(item: item, height: 3)
                .padding(.leading, 42)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.black.opacity(0.10))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(metadata.displayName), \(item.statusText)")
    }

    private var metadata: InProgressMetadata {
        InProgressMetadata(
            item: item,
            installed: store.packages.first { $0.name == item.name && $0.kind == item.kind },
            catalog: catalogStore?.packages.first { $0.name == item.name && $0.kind == item.kind }
        )
    }
}
