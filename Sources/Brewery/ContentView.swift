import AppKit
import BreweryCore
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: PackageStore
    @StateObject private var catalogStore = CatalogStore()
    @AppStorage("packageDetailPaneWidth") private var detailPaneWidth = 420.0

    /// The info pane exists exactly while something is selected: picking a
    /// package opens it, closing it deselects the package.
    private var isDetailPaneVisible: Bool {
        switch store.filter {
        case .browse: return selectedCatalogPackage != nil
        case .library: return store.selectedPackage != nil
        case .diagnostics: return false
        }
    }

    private func closeDetailPane() {
        withAnimation(.easeInOut(duration: 0.18)) {
            selectedCatalogPackage = nil
            store.selectedPackageID = nil
        }
    }
    @State private var pendingAction: BrewAction?
    @State private var selectedCatalogPackage: CatalogPackage?

    private let minimumDetailPaneWidth = 380.0
    private let maximumDetailPaneWidth = 640.0
    /// Below this much room right of the sidebar, a side pane starves the
    /// content column, so the detail pane moves underneath instead.
    private let stackDetailBelowWidth = 900.0

    var body: some View {
        Group {
            if store.service.brewPath == nil {
                MissingHomebrewView(report: store.service.detectionReport)
                    .background(Color.pageBackground)
            } else {
                mainInterface
            }
        }
        .solidTitleBar()
        .task {
            await store.refresh()
            await catalogStore.load(installedPackages: store.packages)
        }
        .onChange(of: store.packages) { packages in
            catalogStore.mergeInstalledState(packages)
        }
        .sheet(item: $pendingAction) { action in
            ConfirmationSheet(action: action) {
                pendingAction = nil
            } confirm: {
                pendingAction = nil
                Task { await store.perform(action) }
            }
        }
    }

    private var mainInterface: some View {
        VStack(spacing: 0) {
            NavigationBar()
            Divider()

            Group {
                GeometryReader { geometry in
                    if geometry.size.width < stackDetailBelowWidth {
                        VStack(spacing: 0) {
                            contentPane
                                .frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)

                            if isDetailPaneVisible {
                                Divider()

                                // Only as tall as its columns need; past half the
                                // window it scrolls rather than pushing content up.
                                // The cap goes inside fixedSize: the other way
                                // round, frame(maxHeight:) makes the pane flexible
                                // again and the stack hands it half the window.
                                detailPane(isStacked: true)
                                    .frame(maxHeight: geometry.size.height * 0.5)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    } else {
                        HStack(spacing: 0) {
                            contentPane
                                .frame(minWidth: 400, maxWidth: .infinity)

                            if isDetailPaneVisible {
                                DetailPaneResizeHandle()
                                    .gesture(detailPaneResizeGesture(containerFrame: geometry.frame(in: .global)))

                                detailPane(isStacked: false)
                                    .frame(width: clampedDetailPaneWidth)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            detailPaneWidth = clampedDetailPaneWidth
        }
    }

    private func detailPane(isStacked: Bool) -> some View {
        Group {
            if store.filter == .browse {
                CatalogPackageDetailView(package: selectedCatalogPackage, isStacked: isStacked) { action in
                    pendingAction = action
                } onSelectInstalled: { node in
                    store.selectPackage(node)
                }
            } else {
                PackageDetailView(package: store.selectedPackage, isStacked: isStacked) { node in
                    store.selectPackage(node)
                } onAction: { action in
                    pendingAction = action
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            Button(action: closeDetailPane) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .frame(width: 26, height: 26)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)
            .help("Close and deselect (Esc)")
            .padding(6)
        }
    }

    private var contentPane: some View {
        VStack(spacing: 0) {
            if store.filter == .library {
                packageSearchHeader
                Divider()
            }

            if store.filter == .browse {
                BrowseView(catalogStore: catalogStore, installedPackages: store.packages, selectedPackage: $selectedCatalogPackage) { action in
                    pendingAction = action
                } onSelectInstalled: { node in
                    store.selectPackage(node)
                }
            } else if store.filter == .diagnostics {
                DiagnosticsView { action in
                    pendingAction = action
                }
            } else {
                InstalledPackagesView.library { action in
                    pendingAction = action
                }
            }
        }
        .background(Color.pageBackground)
    }

    private var packageSearchHeader: some View {
        HStack {
            TextField("Search packages", text: $store.searchText)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 360)

            Spacer()

            if store.isRunningCommand {
                ProgressView()
                    .controlSize(.small)
            }

            Text(store.statusMessage)
                .foregroundColor(.secondary)
                .lineLimit(1)

            Button {
                Task { await store.refresh() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .disabled(store.isRunningCommand)
            .help("Reload installed packages and their status")
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
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
        // The window background behind the handle is the dark chrome grey in
        // light mode; keep the strip the colour of the pane beside it.
        .background(Color(nsColor: .dynamic(dark: .clear, light: .controlBackgroundColor)))
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
