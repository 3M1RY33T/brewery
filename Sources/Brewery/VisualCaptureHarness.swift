import AppKit
import BreweryCore
import SwiftUI

/// Set on views rendered by the offscreen harness, so they swap their
/// ScrollView for a plain container (ImageRenderer cannot lay out a
/// ScrollView). Defaults to false in the live app. Defined unconditionally so
/// the `@Environment(\.isRenderHarness)` reference in InstalledPackagesView
/// compiles in release too.
private struct IsRenderHarnessKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isRenderHarness: Bool {
        get { self[IsRenderHarnessKey.self] }
        set { self[IsRenderHarnessKey.self] = newValue }
    }
}

#if DEBUG
/// Renders each changed surface offscreen with `ImageRenderer` and writes PNGs
/// to /tmp/brewery-visual/, so the UI can be inspected without Screen
/// Recording. Activated by `--capture-visual`. Excluded from release builds.
@MainActor
@available(macOS 13.0, *)
enum VisualCaptureHarness {
    static func runIfRequested() async {
        guard CommandLine.arguments.contains("--capture-visual") else { return }
        let out = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(".visual-capture", isDirectory: true)
        try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

        let service = MockBrewService()
        service.simulatesDownloads = true
        service.simulatedPhaseDelay = 0.6
        let store = PackageStore(
            service: service,
            passwordVault: MockPasswordVault(),
            downloadLinger: 60
        )
        let catalogStore = CatalogStore()
        let updateManager = UpdateManager()

        // 1. Launch skeleton (Browse + Library). The Library skeleton's
        // ScrollView cannot be laid out by ImageRenderer, so render its inner
        // content directly (the live window lays out the ScrollView fine).
        render(BrowseSkeletonView(), to: out.appendingPathComponent("01-launch-browse-skeleton.png"), size: CGSize(width: 900, height: 640))
        render(LibrarySkeletonView().librarySkeletonContent, to: out.appendingPathComponent("02-launch-library-skeleton.png"), size: CGSize(width: 900, height: 640))

        // 2 & 3. Load inventory so the Library has categories, then start a
        // live run (warp cask) and queue htop behind it, and render the
        // popover and Library while warp is mid-download.
        await store.refresh()
        let run = Task { await store.perform(.install(name: "warp", kind: .cask)) }
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        let queue = Task { await store.perform(.install(name: "htop", kind: .formula)) }
        try? await Task.sleep(nanoseconds: 400_000_000)

        let popover = DownloadsPopover(catalogStore: catalogStore) {}
            .environmentObject(store)
        render(popover, to: out.appendingPathComponent("03-downloads-popover.png"), size: CGSize(width: 360, height: 320))

        let library = InstalledPackagesView.library(catalogStore: catalogStore) { _ in }
            .environmentObject(store)
            .environment(\.isRenderHarness, true)
        render(library, to: out.appendingPathComponent("04-library-inprogress.png"), size: CGSize(width: 900, height: 640))

        _ = await run.value
        _ = await queue.value

        // 4. Floating update card.
        updateManager.simulateUpdateAvailable()
        let card = UpdateCard()
            .environmentObject(updateManager)
        render(card, to: out.appendingPathComponent("05-update-card.png"), size: CGSize(width: 400, height: 200))

        // 5. Diagnostics: update block + check button + toggle + sudo notice.
        let diagnostics = DiagnosticsView { _ in }
            .environmentObject(store)
            .environmentObject(updateManager)
            .environment(\.isRenderHarness, true)
        render(diagnostics, to: out.appendingPathComponent("06-diagnostics.png"), size: CGSize(width: 900, height: 640))

        // 6. Confirmation sheet with the sudo notice.
        let action = BrewAction.install(name: "rectangle", kind: .cask)
        let sheet = ConfirmationSheet(action: action, sudoNotice: store.sudoAuthentication.preemptionNotice, cancel: {}, confirm: {})
        render(sheet, to: out.appendingPathComponent("07-confirmation-sudo-notice.png"), size: CGSize(width: 460, height: 420))

        print("VISUAL-CAPTURE-DONE \(out.path)")
        exit(0)
    }

    private static func render<V: View>(_ view: V, to url: URL, size: CGSize) {
        // Force light appearance and an opaque page background: the app's
        // `pageBackground` is clear in dark mode, and ImageRenderer defaults to
        // dark, which left the skeleton and Library renders transparent black.
        let content = view
            .frame(width: size.width, height: size.height)
            .background(Color(nsColor: NSColor(srgbRed: 0.918, green: 0.925, blue: 0.937, alpha: 1)))
            .environment(\.colorScheme, .light)
        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        renderer.isOpaque = true
        if let image = renderer.nsImage,
           let tiff = image.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            try? png.write(to: url)
            print("WROTE \(url.lastPathComponent)")
        } else {
            print("FAILED \(url.lastPathComponent)")
        }
    }
}

/// A password vault that reports no saved password, so the confirmation sheet
/// and diagnostics render their "no saved password" state deterministically.
private final class MockPasswordVault: PasswordVaulting {
    var hasSavedPassword: Bool { false }
    var isAvailable: Bool { true }
    func save(_ password: String) throws {}
    func forget() {}
    func unlock(reason: String) async -> PasswordVaultUnlock { .declined }
}
#endif
