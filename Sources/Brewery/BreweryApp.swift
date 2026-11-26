import BreweryCore
import SwiftUI

@main
struct BreweryApp: App {
    @StateObject private var store: PackageStore
    @StateObject private var pinnedStore = PinnedStore()
    @StateObject private var updateManager: UpdateManager

    init() {
        #if DEBUG
        if #available(macOS 13.0, *) {
            Task { await VisualCaptureHarness.runIfRequested() }
        }
        // Verification seam: a debug build launched with --demo runs the real
        // interface against a mock brew that prints downloadable phases, so
        // the popover and queue can be exercised without installing anything.
        if CommandLine.arguments.contains("--demo") {
            let service = MockBrewService()
            service.simulatesDownloads = true
            // `--demo-delay 3` slows the simulated phases so a run can be
            // watched (and clicked through) at human speed.
            if let index = CommandLine.arguments.firstIndex(of: "--demo-delay"),
               index + 1 < CommandLine.arguments.count,
               let delay = Double(CommandLine.arguments[index + 1]) {
                service.simulatedPhaseDelay = delay
            }
            _store = StateObject(wrappedValue: PackageStore(service: service))
            _updateManager = StateObject(wrappedValue: UpdateManager())
            return
        }
        #endif
        _store = StateObject(wrappedValue: PackageStore())
        _updateManager = StateObject(wrappedValue: UpdateManager())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(pinnedStore)
                .environmentObject(updateManager)
                .frame(minWidth: 720, minHeight: 560)
                .task {
                    PackageIconLoader.shared.configure(brewPath: store.service.brewPath)
                }
                .task {
                    // Silent launch check, gated by the auto-check toggle.
                    if updateManager.autoCheckOnLaunch {
                        updateManager.checkForUpdatesInBackground()
                    }
                    #if DEBUG
                    if CommandLine.arguments.contains("--demo-update") {
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        updateManager.simulateUpdateAvailable()
                    }
                    #endif
                }
        }
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Refresh Packages") {
                    Task { await store.refresh() }
                }
                .keyboardShortcut("r", modifiers: [.command])

                Button("Forget Saved Password") {
                    store.forgetSavedPassword()
                }
                .disabled(!store.hasSavedPassword)
                .help("Stop using Touch ID for administrator passwords and delete the saved one")
            }
        }
    }
}
