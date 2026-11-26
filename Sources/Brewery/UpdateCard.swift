import BreweryCore
import SwiftUI

/// The floating, dismissible update notice. Slides in from the bottom-right
/// corner when Sparkle reports a valid update, and slides back out on dismiss.
///
/// It is discovery only: Install hands off to Sparkle's standard window, and
/// "Download page" opens the GitHub releases page. Release notes deliberately
/// do not appear here — the update log lives on the Diagnostics page.
struct UpdateCard: View {
    @EnvironmentObject private var updateManager: UpdateManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // The ZStack stays in the hierarchy whether or not a card is showing,
        // so the animation binding below can animate both insertion and removal.
        ZStack {
            if case .updateAvailable(let release) = updateManager.state {
                card(release)
                    .transition(transition)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: updateManager.state)
    }

    private var transition: AnyTransition {
        reduceMotion ? .opacity : .move(edge: .trailing).combined(with: .opacity)
    }

    private func card(_ release: ReleaseInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Update available")
                        .font(.headline)
                    Text("Brewery \(release.displayVersion) is ready to install.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Button(action: updateManager.dismissCurrentUpdate) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Dismiss this update notice")
            }

            HStack(spacing: 8) {
                Button(action: updateManager.installCurrentUpdate) {
                    Label("Install", systemImage: "arrow.down.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(action: updateManager.openDownloadPage) {
                    Label("Download page", systemImage: "safari")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(14)
        .frame(width: 340)
        .background(Color.cardBackground)
        .cornerRadius(10)
        .cardEdge(cornerRadius: 10)
        .padding(16)
    }
}
