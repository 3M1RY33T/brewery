import BreweryCore
import SwiftUI

struct CommandLogView: View {
    @EnvironmentObject private var store: PackageStore

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Command Log")
                    .font(.headline)
                Spacer()
                Button {
                    store.clearLog()
                } label: {
                    Label("Clear", systemImage: "xmark.circle")
                }
                .disabled(store.logEntries.isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(store.logEntries) { entry in
                            Text(entry.text)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(color(for: entry.stream))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(entry.id)
                        }
                    }
                    .padding(10)
                }
                .onChange(of: store.logEntries.count) { _ in
                    if let last = store.logEntries.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .background(Color(nsColor: .textBackgroundColor))
        }
    }

    private func color(for stream: CommandLogEntry.Stream) -> Color {
        switch stream {
        case .stdout: return .primary
        case .stderr: return .red
        case .status: return .secondary
        }
    }
}
