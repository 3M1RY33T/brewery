import AppKit
import BreweryCore
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: PackageStore
    @AppStorage("packageDetailPaneWidth") private var detailPaneWidth = 420.0
    @State private var pendingAction: BrewAction?
    @State private var installName = ""
    @State private var installKind: PackageKind = .formula
    @State private var showingInstallSheet = false

    private let minimumDetailPaneWidth = 380.0
    private let maximumDetailPaneWidth = 640.0

    var body: some View {
        Group {
            if store.service.brewPath == nil {
                MissingHomebrewView(report: store.service.detectionReport)
            } else {
                mainInterface
            }
        }
        .task {
            await store.refresh()
        }
        .sheet(item: $pendingAction) { action in
            ConfirmationSheet(action: action) {
                pendingAction = nil
            } confirm: {
                pendingAction = nil
                Task { await store.perform(action) }
            }
        }
        .sheet(isPresented: $showingInstallSheet) {
            InstallSheet(name: $installName, kind: $installKind) {
                showingInstallSheet = false
            } confirm: {
                let trimmed = installName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                showingInstallSheet = false
                pendingAction = .install(name: trimmed, kind: installKind)
                installName = ""
            }
        }
    }

    private var mainInterface: some View {
        VStack(spacing: 0) {
            HSplitView {
                SidebarView()
                    .frame(minWidth: 160, idealWidth: 190, maxWidth: 240)

                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        contentPane
                            .frame(minWidth: 560, maxWidth: .infinity)

                        DetailPaneResizeHandle()
                            .gesture(detailPaneResizeGesture(containerFrame: geometry.frame(in: .global)))

                        PackageDetailView(package: store.selectedPackage) { node in
                            store.selectPackage(node)
                        } onAction: { action in
                            pendingAction = action
                        }
                        .frame(width: clampedDetailPaneWidth)
                    }
                }
                .frame(minWidth: 940)
            }

            Divider()

            CommandLogView()
                .frame(height: 170)
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    Task { await store.refresh() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(store.isRunningCommand)

                Button {
                    pendingAction = .update
                } label: {
                    Label("Update", systemImage: "arrow.down.circle")
                }
                .disabled(store.isRunningCommand)

                Button {
                    showingInstallSheet = true
                } label: {
                    Label("Install", systemImage: "plus.circle")
                }
                .disabled(store.isRunningCommand)

                Button {
                    pendingAction = .cleanup
                } label: {
                    Label("Cleanup", systemImage: "sparkles")
                }
                .disabled(store.isRunningCommand)
            }
        }
        .onAppear {
            detailPaneWidth = clampedDetailPaneWidth
        }
    }

    private var contentPane: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Search packages", text: $store.searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 320)

                Spacer()

                if store.isRunningCommand {
                    ProgressView()
                        .controlSize(.small)
                }

                Text(store.statusMessage)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(12)

            Divider()

            if store.filter == .diagnostics {
                DiagnosticsView()
            } else {
                PackageTableView()
            }
        }
    }

    private func detailPaneResizeGesture(containerFrame: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                let proposedWidth = containerFrame.maxX - value.location.x
                detailPaneWidth = clampedDetailPaneWidth(proposedWidth)
            }
            .onEnded { _ in
                detailPaneWidth = clampedDetailPaneWidth
            }
    }

    private var clampedDetailPaneWidth: Double {
        clampedDetailPaneWidth(detailPaneWidth)
    }

    private func clampedDetailPaneWidth(_ width: Double) -> Double {
        min(max(width, minimumDetailPaneWidth), maximumDetailPaneWidth)
    }
}

private struct DetailPaneResizeHandle: View {
    var body: some View {
        ZStack {
            ResizeCursorArea()
            Rectangle()
                .fill(Color(nsColor: .separatorColor))
                .frame(width: 1)
        }
        .frame(width: 10)
        .contentShape(Rectangle())
        .help("Drag to resize package details")
        .zIndex(1)
    }
}

private struct ResizeCursorArea: NSViewRepresentable {
    func makeNSView(context: Context) -> CursorTrackingView {
        CursorTrackingView()
    }

    func updateNSView(_ nsView: CursorTrackingView, context: Context) {}
}

private final class CursorTrackingView: NSView {
    private var trackingArea: NSTrackingArea?
    private var cursorIsPushed = false

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let trackingArea {
            removeTrackingArea(trackingArea)
        }

        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self
        )
        trackingArea = area
        addTrackingArea(area)
    }

    override func mouseEntered(with event: NSEvent) {
        guard !cursorIsPushed else { return }
        NSCursor.resizeLeftRight.push()
        cursorIsPushed = true
    }

    override func mouseExited(with event: NSEvent) {
        popCursorIfNeeded()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil {
            popCursorIfNeeded()
        }
    }

    private func popCursorIfNeeded() {
        guard cursorIsPushed else { return }
        NSCursor.pop()
        cursorIsPushed = false
    }
}
