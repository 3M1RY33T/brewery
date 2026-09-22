import BreweryCore
import SwiftUI

@main
struct BreweryApp: App {
    @StateObject private var store = PackageStore()
    @StateObject private var pinnedStore = PinnedStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(pinnedStore)
                .frame(minWidth: 720, minHeight: 560)
                .task {
                    PackageIconLoader.shared.configure(brewPath: store.service.brewPath)
                }
        }
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Refresh Packages") {
                    Task { await store.refresh() }
                }
                .keyboardShortcut("r", modifiers: [.command])
            }
        }
    }
}
