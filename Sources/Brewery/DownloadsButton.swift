import BreweryCore
import SwiftUI

/// The Browse header's downloads control: a ring that fills as the run moves,
/// a badge for everything waiting, and a popover listing the whole queue.
struct DownloadsButton: View {
    @EnvironmentObject private var store: PackageStore
    @ObservedObject var catalogStore: CatalogStore
    /// Switches to Diagnostics and closes the popover.
    let showLog: () -> Void

    @State private var isShowingPopover = false

    private var session: DownloadSession? { store.downloads }
    private var activeCount: Int { session?.activeCount ?? 0 }

    var body: some View {
        Button {
            isShowingPopover.toggle()
        } label: {
            HStack(spacing: 5) {
                icon

                Text("Downloads")

                if activeCount > 0 {
                    Text("\(activeCount)")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Color.chipBackground)
                        .cornerRadius(5)
                }
            }
        }
        .buttonStyle(.bordered)
        .tint(session?.isRunning == true ? .accentColor : nil)
        .help(session?.hasFailure == true
              ? "An action failed — open for the message and the log"
              : "Packages downloading, installing and waiting in the queue")
        .popover(isPresented: $isShowingPopover, arrowEdge: .bottom) {
            DownloadsPopover(catalogStore: catalogStore) {
                isShowingPopover = false
                showLog()
            }
        }
    }

    /// A determinate ring while something is running, the plain glyph
    /// otherwise: the same control, saying whether it has news.
    @ViewBuilder
    private var icon: some View {
        if let session, session.isRunning {
            RingProgress(fraction: session.activeItem?.progress ?? session.fraction)
                .frame(width: 14, height: 14)
        } else if session?.hasFailure == true {
            // A failed entry leaves its Library category once it settles, so
            // the button is what keeps the failure from passing unnoticed.
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)
        } else {
            Image(systemName: "arrow.down.circle")
        }
    }
}

/// The popover: what is downloading, what is queued, and the way to the log.
struct DownloadsPopover: View {
    @EnvironmentObject private var store: PackageStore
    @ObservedObject var catalogStore: CatalogStore
    let showLog: () -> Void

    private var session: DownloadSession? { store.downloads }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(12)

            Divider()

            if let session, !session.items.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(session.items.enumerated()), id: \.element.id) { index, item in
                            if index > 0 {
                                Divider()
                                    .padding(.leading, 50)
                            }
                            DownloadRow(item: item, catalogStore: catalogStore) {
                                store.cancelQueuedItem(item.id)
                            }
                        }
                    }
                }
                .frame(maxHeight: 360)
            } else {
                emptyState
            }

            Divider()
            footer
                .padding(10)
        }
        .frame(width: 360)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Label("Downloads", systemImage: "arrow.down.circle")
                .font(.headline)

            if let session, session.activeCount > 0 {
                Text("\(session.activeCount)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(Color.chipBackground)
                    .cornerRadius(5)
            }

            Spacer(minLength: 8)

            if let session, !session.isRunning {
                Button(session.hasFailure ? "Dismiss" : "Clear Finished") {
                    store.clearDownloadSession()
                }
                .buttonStyle(.plain)
                .font(.callout)
                .foregroundColor(.accentColor)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Nothing downloading")
                .font(.callout.weight(.medium))
            Text("Confirmed installs and upgrades appear here with live progress while they run, and wait their turn if one is already going.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }

    private var footer: some View {
        HStack {
            Button(action: showLog) {
                Label("Show Command Log", systemImage: "text.alignleft")
                    .font(.callout)
            }
            .buttonStyle(.plain)
            .foregroundColor(.accentColor)

            Spacer()

            if !store.queuedActions.isEmpty {
                Button("Clear Queue") {
                    store.clearQueuedActions()
                }
                .buttonStyle(.plain)
                .font(.callout)
                .foregroundColor(.secondary)
            }
        }
    }
}

/// A small ring that fills clockwise from the top.
struct RingProgress: View {
    let fraction: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.25), lineWidth: 2)
            Circle()
                .trim(from: 0, to: min(max(fraction, 0), 1))
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .animation(.easeOut(duration: 0.2), value: fraction)
    }
}
