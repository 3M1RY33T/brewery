import BreweryCore
import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var store: PackageStore

    var body: some View {
        List {
            Section("Library") {
                ForEach(PackageFilter.allCases) { filter in
                    Button {
                        store.filter = filter
                    } label: {
                        Label(filter.title, systemImage: icon(for: filter))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(store.filter == filter ? .accentColor : .primary)
                }
            }
        }
        .listStyle(.sidebar)
    }

    private func icon(for filter: PackageFilter) -> String {
        switch filter {
        case .browse: return "square.grid.2x2"
        case .all: return "shippingbox"
        case .formulae: return "terminal"
        case .casks: return "macwindow"
        case .outdated: return "exclamationmark.arrow.triangle.2.circlepath"
        case .pinned: return "pin"
        case .diagnostics: return "stethoscope"
        }
    }
}
