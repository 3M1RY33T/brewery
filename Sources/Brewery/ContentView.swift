import AppKit
import BreweryCore
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: PackageStore
    @StateObject private var catalogStore = CatalogStore()
    @AppStorage("packageDetailPaneWidth") private var detailPaneWidth = 420.0
    /// The inspector is dismissable; closing it is remembered like its width.
    @AppStorage("packageDetailPaneVisible") private var isDetailPaneVisible = true
    @State private var pendingAction: BrewAction?
    @State private var installName = ""
    @State private var installKind: PackageKind = .formula
    @State private var showingInstallSheet = false
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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { isDetailPaneVisible.toggle() }
                } label: {
                    Label("Package Info", systemImage: "sidebar.trailing")
                }
                .keyboardShortcut("i", modifiers: [.command, .option])
                .help(isDetailPaneVisible ? "Hide package info (⌥⌘I)" : "Show package info (⌥⌘I)")
            }

            ToolbarItemGroup {
                Button {
                    Task { await store.refresh() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(store.isRunningCommand)
                .help("Refresh installed packages and status")

                Button {
                    pendingAction = .update
                } label: {
                    Label("Update", systemImage: "arrow.down.circle")
                }
                .disabled(store.isRunningCommand)
                .help("Run brew update")

                Button {
                    showingInstallSheet = true
                } label: {
                    Label("Install", systemImage: "plus.circle")
                }
                .disabled(store.isRunningCommand)
                .help("Install a formula or cask")

                Button {
                    pendingAction = .cleanup
                } label: {
                    Label("Cleanup", systemImage: "sparkles")
                }
                .disabled(store.isRunningCommand)
                .help("Run brew cleanup")
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
            Button {
                withAnimation(.easeInOut(duration: 0.18)) { isDetailPaneVisible = false }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .frame(width: 26, height: 26)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Hide package info (⌥⌘I)")
            .padding(6)
        }
    }

    private var contentPane: some View {
        VStack(spacing: 0) {
            if store.filter != .browse {
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
                DiagnosticsView()
            } else {
                InstalledPackagesView.library { action in
                    pendingAction = action
                }
            }
        }
    }

    private var packageSearchHeader: some View {
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
