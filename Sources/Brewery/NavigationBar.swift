import BreweryCore
import SwiftUI

/// The three sections as a centred row of pills under the title bar.
///
/// A sidebar earned its column when it listed seven views; with three it was
/// mostly empty space taken from the content.
struct NavigationBar: View {
    @EnvironmentObject private var store: PackageStore

    var body: some View {
        HStack(spacing: 6) {
            ForEach(PackageFilter.allCases) { filter in
                let isActive = store.filter == filter
                Button {
                    store.filter = filter
                } label: {
                    Label(filter.title, systemImage: icon(for: filter))
                        .font(.callout.weight(.medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(isActive ? Color.navSelection : Color.clear)
                        .cornerRadius(8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundColor(isActive ? .primary : .secondary)
                .help(filter.title)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func icon(for filter: PackageFilter) -> String {
        switch filter {
        case .browse: return "square.grid.2x2"
        case .library: return "books.vertical"
        case .diagnostics: return "stethoscope"
        }
    }
}
