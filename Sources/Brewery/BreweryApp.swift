import BreweryCore
import SwiftUI

@main
struct BreweryApp: App {
    @StateObject private var store = PackageStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 1080, minHeight: 720)
        }
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
