import BreweryCore
import SwiftUI

struct DiagnosticsView: View {
    @EnvironmentObject private var store: PackageStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Diagnostics")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
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
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(6)
        }
    }
}
