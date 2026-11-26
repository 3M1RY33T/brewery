import BreweryCore
import SwiftUI

/// Homebrew's own health checks, with the command log beneath them. The log
/// used to sit under every page; it belongs with the diagnostics, which is
/// where you go when something needs explaining.
struct DiagnosticsView: View {
    @EnvironmentObject private var store: PackageStore
    @EnvironmentObject private var updateManager: UpdateManager
    @Environment(\.isRenderHarness) private var isRenderHarness
    let onAction: (BrewAction) -> Void

    var body: some View {
        if isRenderHarness {
            // ImageRenderer cannot lay out a VSplitView, so the offscreen
            // verification harness renders the report directly.
            report
        } else {
            VSplitView {
                report
                    .frame(minHeight: 180)
                CommandLogView()
                    .frame(minHeight: 140, idealHeight: 240)
            }
        }
    }

    private var report: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Diagnostics")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    updateManager.checkForUpdatesInBackground()
                } label: {
                    Label("Check for Updates", systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(updateManager.state == .checking)
                .help("Check for a new version of Brewery")

                Button {
                    onAction(.cleanup)
                } label: {
                    Label("Clean Up", systemImage: "sparkles")
                }
                .disabled(store.isRunningCommand)
                .help("Run brew cleanup to remove stale downloads and old versions")

                Button {
                    Task { await store.loadDiagnostics() }
                } label: {
                    Label("Run Diagnostics", systemImage: "play.circle")
                }
                .disabled(store.isRunningCommand)
            }

            SudoAuthenticationBlock(report: store.sudoAuthentication)

            UpdateBlock()

            if let diagnostics = store.diagnostics {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        DiagnosticsBlock(title: "Version", text: diagnostics.version)
                        DiagnosticsBlock(title: "Config", text: diagnostics.config)
                        DiagnosticsBlock(title: "Doctor", text: diagnostics.doctor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                Spacer()
                Text("Run diagnostics to inspect the active Homebrew installation.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            }
        }
        .padding(16)
    }
}

struct DiagnosticsBlock: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(text)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color.cardBackground)
                .cornerRadius(6)
                .cardEdge(cornerRadius: 6)
        }
    }
}

/// The update log: current version, whether an update is available, the
/// "What's new" release notes for it, and the launch auto-check toggle.
struct UpdateBlock: View {
    @EnvironmentObject private var updateManager: UpdateManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.secondary)
                Text("Updates")
                    .font(.headline)
                Spacer()
                Toggle("Check on launch", isOn: $updateManager.autoCheckOnLaunch)
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }

            Text(currentVersionLine)
                .font(.callout)
                .foregroundColor(.secondary)

            status
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .cornerRadius(6)
        .cardEdge(cornerRadius: 6)
    }

    private var currentVersionLine: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "Current version \(version) (build \(build))"
    }

    @ViewBuilder
    private var status: some View {
        switch updateManager.state {
        case .idle:
            EmptyView()
        case .checking:
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text("Checking for updates…")
                    .foregroundColor(.secondary)
            }
        case .upToDate:
            Label("Brewery is up to date.", systemImage: "checkmark.circle")
                .foregroundColor(.secondary)
        case .updateAvailable(let release):
            VStack(alignment: .leading, spacing: 6) {
                Label("Update available: Brewery \(release.displayVersion)", systemImage: "arrow.down.circle")
                    .foregroundColor(.accentColor)
                if !release.releaseNotes.isEmpty {
                    Text(release.releaseNotes)
                        .font(.system(.caption))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color.wellBackground)
                        .cornerRadius(4)
                }
            }
        case .failed(let message):
            Label("Update check failed: \(message)", systemImage: "exclamationmark.triangle")
                .foregroundColor(.secondary)
        }
    }
}

/// How this Mac's `sudo` will authenticate, always visible on the
/// Diagnostics page (no Homebrew run needed to read the PAM files).
struct SudoAuthenticationBlock: View {
    let report: SudoPAMReport

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .foregroundColor(.secondary)
                Text("Sudo authentication")
                    .font(.headline)
            }
            Text(report.explanation)
                .font(.callout)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if report.canPreemptPassword {
                Text(guidance)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .cornerRadius(6)
        .cardEdge(cornerRadius: 6)
    }

    private var symbol: String {
        if report.usesTouchID { return "touchid" }
        if report.usesSmartcard { return "creditcard" }
        return "lock.fill"
    }

    private var guidance: String {
        let files = report.sources.joined(separator: " and ")
        return "To always prompt for a password instead, remove or comment out the Touch ID / smartcard line in \(files), then reopen Brewery."
    }
}
