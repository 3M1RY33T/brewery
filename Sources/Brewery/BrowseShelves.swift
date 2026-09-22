import BreweryCore
import SwiftUI

// MARK: - Shared

extension Color {
    /// A package or category tint, readable against both appearances.
    static func brewery(hue: Double, saturation: Double = 0.55, brightness: Double = 0.62) -> Color {
        Color(hue: hue, saturation: saturation, brightness: brightness)
    }
}

/// The Install / Upgrade / Installed control, sized for dense shelves.
struct InstallButton: View {
    let package: CatalogPackage
    var compact = false
    let action: () -> Void

    var body: some View {
        Button(package.installStatus.title, action: action)
            .controlSize(compact ? .small : .regular)
            .disabled(package.installStatus == .installed(outdated: false))
    }
}

/// The App Store's "See All" affordance, as a reversible toggle.
struct ShowMoreButton: View {
    let isExpanded: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(isExpanded ? "Show Less" : "Show More", systemImage: isExpanded ? "chevron.up" : "chevron.down")
                .font(.callout.weight(.medium))
        }
        .buttonStyle(.plain)
        .foregroundColor(.accentColor)
    }
}

struct ShelfHeader: View {
    let title: String
    let systemImage: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(title, systemImage: systemImage)
                .font(.title2.weight(.semibold))
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Hero

/// Full-width gradient cards for the most installed casks, the way the App
/// Store leads with a handful of editorial picks.
struct HeroCarousel: View {
    let packages: [CatalogPackage]
    @Binding var selectedPackage: CatalogPackage?
    let action: (CatalogPackage) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(packages) { package in
                    HeroCard(
                        package: package,
                        isSelected: selectedPackage?.id == package.id,
                        open: { selectedPackage = package },
                        action: { action(package) }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
        }
    }
}

private struct HeroCard: View {
    let package: CatalogPackage
    let isSelected: Bool
    let open: () -> Void
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("MOST INSTALLED")
                .font(.caption2.weight(.bold))
                .tracking(1.1)
                .foregroundColor(.white.opacity(0.75))

            Spacer(minLength: 10)

            HStack(alignment: .bottom, spacing: 14) {
                PackageIconView(package: package, size: 72, cornerRadius: 16)

                VStack(alignment: .leading, spacing: 4) {
                    Text(package.displayName)
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(package.description ?? package.name)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                InstallButton(package: package, action: action)
            }
        }
        .padding(18)
        .frame(width: 460, height: 168, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [
                    .brewery(hue: package.tintHue, saturation: 0.62, brightness: 0.55),
                    .brewery(hue: package.tintHue, saturation: 0.75, brightness: 0.30)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: open)
    }
}

// MARK: - Category tiles

/// The App Store's Categories page: coloured tiles that jump to a shelf.
struct CategoryTileGrid: View {
    let sections: [CatalogSection]
    let jump: (String) -> Void

    /// Rows shown before the rest folds away behind the toggle.
    static let collapsedRows = 2
    private static let minimumTileWidth: CGFloat = 150
    private static let spacing: CGFloat = 10

    @State private var isExpanded = false
    @State private var availableWidth: CGFloat = 0

    /// Column count for the width we actually have, so "two rows" is exact
    /// rather than a guess that breaks when the window is resized.
    private var columnCount: Int {
        guard availableWidth > 0 else { return 5 }
        let fit = (availableWidth + Self.spacing) / (Self.minimumTileWidth + Self.spacing)
        return max(2, Int(fit))
    }

    private var collapsedCount: Int { columnCount * Self.collapsedRows }
    private var canToggle: Bool { sections.count > collapsedCount }

    private var visible: [CatalogSection] {
        isExpanded || !canToggle ? sections : Array(sections.prefix(collapsedCount))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            grid

            if canToggle {
                ShowMoreButton(isExpanded: isExpanded) {
                    withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
                }
            }
        }
        .background(
            GeometryReader { geometry in
                Color.clear.preference(key: WidthPreference.self, value: geometry.size.width)
            }
        )
        .onPreferenceChange(WidthPreference.self) { availableWidth = $0 }
    }

    private var grid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: Self.spacing), count: columnCount)

        return LazyVGrid(columns: columns, spacing: Self.spacing) {
            ForEach(visible) { section in
                Button {
                    jump(section.id)
                } label: {
                    HStack(spacing: 9) {
                        Image(systemName: section.category.systemImage)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                            .background(Color.brewery(hue: section.category.tintHue))
                            .cornerRadius(7)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(section.category.title)
                                .font(.callout.weight(.medium))
                                .lineLimit(1)
                            Text("\(section.caskTotal + section.formulaTotal)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(9)
                    .frame(maxWidth: .infinity)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(9)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct WidthPreference: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Top charts

/// Two numbered charts side by side, ranked by real install counts.
struct TopChartsShelf: View {
    let casks: [CatalogPackage]
    let formulae: [CatalogPackage]
    @Binding var selectedPackage: CatalogPackage?
    let action: (CatalogPackage) -> Void

    /// Rows revealed at first and added per click. Both columns page
    /// together so they stay the same height.
    static let pageSize = 10

    @State private var visibleCount = TopChartsShelf.pageSize

    private var longest: Int { max(casks.count, formulae.count) }
    private var canShowMore: Bool { visibleCount < longest }
    private var canShowLess: Bool { visibleCount > Self.pageSize }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ShelfHeader(
                title: "Top Charts",
                systemImage: "chart.bar.fill",
                subtitle: "Ranked by installs over the last year"
            )

            HStack(alignment: .top, spacing: 14) {
                chart(title: "Casks", packages: Array(casks.prefix(visibleCount)))
                chart(title: "Formulae", packages: Array(formulae.prefix(visibleCount)))
            }

            if canShowMore || canShowLess {
                HStack(spacing: 16) {
                    if canShowMore {
                        ShowMoreButton(isExpanded: false) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                visibleCount = min(visibleCount + Self.pageSize, longest)
                            }
                        }
                    }
                    if canShowLess {
                        ShowMoreButton(isExpanded: true) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                visibleCount = Self.pageSize
                            }
                        }
                    }
                    Spacer()
                    Text("\(min(visibleCount, longest)) of \(longest)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func chart(title: String, packages: [CatalogPackage]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(Array(packages.enumerated()), id: \.element.id) { index, package in
                    if index > 0 { Divider() }
                    ChartRow(
                        rank: index + 1,
                        package: package,
                        isSelected: selectedPackage?.id == package.id,
                        open: { selectedPackage = package },
                        action: { action(package) }
                    )
                }
            }
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ChartRow: View {
    let rank: Int
    let package: CatalogPackage
    let isSelected: Bool
    let open: () -> Void
    let action: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text("\(rank)")
                .font(.system(.callout, design: .rounded).weight(.semibold))
                .foregroundColor(.secondary)
                .frame(width: 20, alignment: .trailing)

            PackageIconView(package: package, size: 32, cornerRadius: 7)

            VStack(alignment: .leading, spacing: 1) {
                Text(package.displayName)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                Text(package.description ?? package.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            InstallButton(package: package, compact: true, action: action)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(isSelected ? Color.accentColor.opacity(0.14) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture(perform: open)
    }
}

// MARK: - Compact grid

/// Three rows of compact cells scrolling sideways: the App Store's layout for
/// shelves with far more items than a single row could show.
struct CompactIconGrid: View {
    let packages: [CatalogPackage]
    @Binding var selectedPackage: CatalogPackage?
    let action: (CatalogPackage) -> Void

    private var columns: [[CatalogPackage]] {
        stride(from: 0, to: packages.count, by: 3).map {
            Array(packages[$0..<min($0 + 3, packages.count)])
        }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                    VStack(spacing: 0) {
                        ForEach(Array(column.enumerated()), id: \.element.id) { index, package in
                            if index > 0 { Divider() }
                            CompactCell(
                                package: package,
                                isSelected: selectedPackage?.id == package.id,
                                open: { selectedPackage = package },
                                action: { action(package) }
                            )
                        }
                    }
                    .frame(width: 340)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

private struct CompactCell: View {
    let package: CatalogPackage
    let isSelected: Bool
    let open: () -> Void
    let action: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            PackageIconView(package: package, size: 36, cornerRadius: 8)

            VStack(alignment: .leading, spacing: 1) {
                Text(package.displayName)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                Text(package.description ?? package.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            InstallButton(package: package, compact: true, action: action)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(height: 56)
        .background(isSelected ? Color.accentColor.opacity(0.14) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture(perform: open)
    }
}

// MARK: - Spotlight

/// One card given real room, with the rest of the shelf listed beside it.
struct SpotlightShelf: View {
    let packages: [CatalogPackage]
    let tintHue: Double
    @Binding var selectedPackage: CatalogPackage?
    let action: (CatalogPackage) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            if let lead = packages.first {
                SpotlightCard(
                    package: lead,
                    tintHue: tintHue,
                    isSelected: selectedPackage?.id == lead.id,
                    open: { selectedPackage = lead },
                    action: { action(lead) }
                )
            }

            VStack(spacing: 0) {
                ForEach(Array(packages.dropFirst().prefix(5).enumerated()), id: \.element.id) { index, package in
                    if index > 0 { Divider() }
                    CompactCell(
                        package: package,
                        isSelected: selectedPackage?.id == package.id,
                        open: { selectedPackage = package },
                        action: { action(package) }
                    )
                }
            }
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(10)
        }
    }
}

private struct SpotlightCard: View {
    let package: CatalogPackage
    let tintHue: Double
    let isSelected: Bool
    let open: () -> Void
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PackageIconView(package: package, size: 56, cornerRadius: 13)

            VStack(alignment: .leading, spacing: 3) {
                Text(package.displayName)
                    .font(.title3.weight(.semibold))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(package.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Text(package.description ?? package.name)
                .font(.callout)
                .foregroundColor(.secondary)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 4)

            Divider()

            HStack {
                Label(package.tap ?? "homebrew/cask", systemImage: "shippingbox")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 6)
                InstallButton(package: package, action: action)
            }
        }
        .padding(16)
        .frame(width: 300, height: 281, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [
                    Color.brewery(hue: tintHue, saturation: 0.30, brightness: 0.34),
                    Color(nsColor: .textBackgroundColor)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: open)
    }
}
