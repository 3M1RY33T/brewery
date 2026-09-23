import BreweryCore
import SwiftUI

/// Homebrew's own health checks, with the command log beneath them. The log
/// used to sit under every page; it belongs with the diagnostics, which is
/// where you go when something needs explaining.
struct DiagnosticsView: View {
    @EnvironmentObject private var store: PackageStore
    let onAction: (BrewAction) -> Void

    var body: some View {
        VSplitView {
            report
                .frame(minHeight: 180)
            CommandLogView()
                .frame(minHeight: 140, idealHeight: 240)
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
