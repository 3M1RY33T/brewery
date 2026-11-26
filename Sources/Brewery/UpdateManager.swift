import BreweryCore
import Sparkle
import SwiftUI

/// Wraps Sparkle and drives Brewery's own update surfaces — the floating card
/// and the Diagnostics block — from Sparkle's `SPUUpdaterDelegate` callbacks
/// rather than Sparkle's default windows being the first thing the user sees.
///
/// Sparkle performs the download, install and relaunch; Brewery owns the
/// notification. A background check (launch, or the Diagnostics button) is
/// silent and only flips this manager's state, so the card appears without
/// Sparkle popping its own window. The card's Install button then calls
/// `checkForUpdates()` — a user-initiated check that lets Sparkle's standard
/// update window take over for the actual install.
@MainActor
final class UpdateManager: NSObject, ObservableObject {
    // MARK: - Published state

    @Published private(set) var state: UpdateState = .idle

    /// Whether Brewery checks for updates on launch. Persisted in UserDefaults.
    /// Brewery drives its own checks (via `checkForUpdateInformation`) gated by
    /// this toggle, rather than relying on Sparkle's scheduler, so the toggle
    /// is authoritative and there is no second, unmanaged scheduled check.
    @Published var autoCheckOnLaunch: Bool {
        didSet {
            UserDefaults.standard.set(autoCheckOnLaunch, forKey: Self.autoCheckKey)
        }
    }

    /// The update currently on offer, when one exists.
    private(set) var currentRelease: ReleaseInfo?

    /// The version the user dismissed, so the same version does not re-nag
    /// until a newer one appears.
    @AppStorage("dismissedUpdateVersion") private var dismissedVersion = ""

    private static let autoCheckKey = "autoCheckForUpdatesOnLaunch"
    private static let downloadPageURL = URL(string: "https://github.com/3M1RY33T/brewery/releases/latest")

    // MARK: - Sparkle

    // Lazy so `self` is available to pass as both delegates after super.init().
    private lazy var controller = SPUStandardUpdaterController(
        startingUpdater: false,
        updaterDelegate: self,
        userDriverDelegate: self
    )

    private var updater: SPUUpdater { controller.updater }

    override init() {
        let stored = UserDefaults.standard.object(forKey: Self.autoCheckKey) as? Bool
        self.autoCheckOnLaunch = stored ?? true
        super.init()
        // Brewery checks on its own schedule (launch, and the Diagnostics
        // button) via checkForUpdateInformation, so Sparkle's own scheduled
        // background checks are switched off to avoid a redundant fetch.
        updater.automaticallyChecksForUpdates = false
        do {
            try updater.start()
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    // MARK: - Actions

    /// A silent, card-driven check that surfaces the result via the delegate
    /// without ever popping Sparkle's own window. Used on launch (gated by
    /// `autoCheckOnLaunch`) and by the Diagnostics "Check for Updates" button.
    ///
    /// `checkForUpdateInformation` is the right Sparkle primitive here: it is a
    /// "probing" check that fires `didFindValidUpdate` / `didNotFindUpdate` but
    /// never offers to install, and — unlike `checkForUpdatesInBackground` — it
    /// is not gated by `automaticallyChecksForUpdates`, so the Diagnostics
    /// button works even when the launch toggle is off.
    func checkForUpdatesInBackground() {
        state = .checking
        updater.checkForUpdateInformation()
    }

    /// A user-initiated check: Sparkle's standard window takes over for the
    /// download/install/relaunch. Called from the card's Install button.
    func checkForUpdates() {
        updater.checkForUpdates()
    }

    func openDownloadPage() {
        guard let url = currentRelease?.downloadURL ?? Self.downloadPageURL else { return }
        NSWorkspace.shared.open(url)
    }

    /// Records the current version as dismissed and hides the card. The same
    /// version won't re-nag until a newer one appears.
    func dismissCurrentUpdate() {
        if let release = currentRelease {
            dismissedVersion = release.versionString
        }
        currentRelease = nil
        state = .upToDate
    }

    /// The card's Install button: remember the version (so the re-check Sparkle
    /// performs does not re-show the card) and hand off to Sparkle's window.
    func installCurrentUpdate() {
        guard let release = currentRelease else { return }
        dismissedVersion = release.versionString
        currentRelease = nil
        state = .upToDate
        checkForUpdates()
    }

    // MARK: - DEBUG seam

    #if DEBUG
    /// Fakes an available update so the card and Diagnostics block can be
    /// exercised with no published appcast or signing key (`--demo-update`).
    ///
    /// Builds a real `SUAppcastItem` — the same payload Sparkle's delegate
    /// delivers from a live feed — and routes it through the actual
    /// `didFindValidUpdate` path, so the demo exercises the real release-notes
    /// formatting and state transition instead of mutating state directly.
    func simulateUpdateAvailable() {
        let enclosure: [String: Any] = [
            "sparkle:version": "99",
            "sparkle:shortVersionString": "9.9.9",
            "url": Self.downloadPageURL!.absoluteString,
            "length": "123456"
        ]
        let payload: [String: Any] = [
            "title": "Brewery 9.9.9",
            "enclosure": enclosure,
            "description": [
                "content": "This is a simulated update, shown by the --demo-update launch flag.",
                "format": "html"
            ]
        ]
        // The public dictionary initializer is deprecated in favour of a
        // private one (SUAppcastItem+Private.h), but it is the only way to
        // fabricate an item without a live appcast, and it is DEBUG-only.
        guard let item = SUAppcastItem(dictionary: payload) else {
            state = .failed("Could not build the --demo-update appcast item")
            return
        }
        updater(updater, didFindValidUpdate: item)
    }
    #endif
}

// MARK: - SPUUpdaterDelegate

extension UpdateManager: SPUUpdaterDelegate {
    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        let release = ReleaseInfo(
            versionString: item.versionString,
            displayVersion: item.displayVersionString,
            releaseNotes: releaseNotes(for: item),
            downloadURL: item.fileURL ?? item.infoURL ?? item.releaseNotesURL,
            publicationDate: item.date
        )
        currentRelease = release
        state = item.versionString == dismissedVersion ? .upToDate : .updateAvailable(release)
    }

    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        currentRelease = nil
        state = .upToDate
    }

    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        currentRelease = nil
        let nsError = error as NSError
        // Sparkle reports "no update found" through `didAbortWithError`
        // (not `didNotFindUpdate`) when a check for update information finds
        // nothing, with `error.code == SUNoUpdateError` and the localized
        // description "You're up to date!". That is a successful, up-to-date
        // result — surfacing it as a failure reads as a contradictory
        // "Update check failed: You're up to date!".
        if nsError.domain == SUSparkleErrorDomain && nsError.code == SUError.noUpdateError.rawValue {
            state = .upToDate
        } else {
            state = .failed(error.localizedDescription)
        }
    }

    private func releaseNotes(for item: SUAppcastItem) -> String {
        guard let description = item.itemDescription else { return "" }
        if item.itemDescriptionFormat?.lowercased() == "plain-text" {
            return description
        }
        return releaseNotesPlainText(fromHTML: description)
    }
}

// MARK: - SPUStandardUserDriverDelegate

extension UpdateManager: SPUStandardUserDriverDelegate {
    /// A background check that finds an update must not pop Sparkle's own
    /// window — Brewery's floating card is the surface for those.
    nonisolated func standardUserDriverShouldHandleShowingScheduledUpdate(_ update: SUAppcastItem, andInImmediateFocus immediateFocus: Bool) -> Bool {
        false
    }
}
