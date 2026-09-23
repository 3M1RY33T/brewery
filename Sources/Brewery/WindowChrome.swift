import AppKit
import SwiftUI

/// Keeps the title bar a solid band above everything else.
///
/// SwiftUI's window group makes the title bar transparent and lets the
/// sidebar run up behind it, so the window title ends up cramped inside the
/// navigation column. This turns that off once the view has a window: the
/// title bar is opaque, ends in a hairline, and the sidebar starts below it.
///
/// In light mode the window background, which the navigation bar shows, is a
/// grey a step below the page, and the title bar a step darker again, so the
/// chrome frames the page. Dark mode keeps the system colours.
struct WindowChrome: NSViewRepresentable {
    func makeNSView(context: Context) -> ChromeView { ChromeView() }
    func updateNSView(_ nsView: ChromeView, context: Context) {}

    final class ChromeView: NSView {
        private var observer: NSObjectProtocol?
        private let titlebarTint = TitlebarTint()

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window else { return }
            apply(to: window)
            // SwiftUI finishes configuring the window after the content view
            // is attached, so apply again once that has happened, and once
            // more when the window first becomes key in case it was late.
            DispatchQueue.main.async { [weak window] in
                window.map(self.apply(to:))
            }
            observer = NotificationCenter.default.addObserver(
                forName: NSWindow.didBecomeKeyNotification, object: window, queue: .main
            ) { [weak self, weak window] _ in
                window.map { self?.apply(to: $0) }
            }
        }

        override func viewDidChangeEffectiveAppearance() {
            super.viewDidChangeEffectiveAppearance()
            window.map(apply(to:))
        }

        private func apply(to window: NSWindow) {
            let isDark = window.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            window.styleMask.remove(.fullSizeContentView)
            window.titlebarAppearsTransparent = false
            window.titlebarSeparatorStyle = .line
            window.titleVisibility = .visible
            window.backgroundColor = isDark ? .windowBackgroundColor : .lightChrome
            installTitlebarTint(in: window)
            titlebarTint.isHidden = isDark
        }

        /// The title bar paints its own opaque background, and SwiftUI turns
        /// `titlebarAppearsTransparent` back off, so a transparent title bar
        /// over the window background does not stick. The colour goes in as a
        /// view behind the title and window buttons instead.
        private func installTitlebarTint(in window: NSWindow) {
            guard titlebarTint.superview == nil,
                  let titlebar = window.standardWindowButton(.closeButton)?.superview else { return }
            titlebarTint.frame = titlebar.bounds
            titlebarTint.autoresizingMask = [.width, .height]
            titlebar.addSubview(titlebarTint, positioned: .above, relativeTo: titlebar.subviews.first)
        }

        deinit {
            if let observer { NotificationCenter.default.removeObserver(observer) }
        }
    }

    /// Fills the title bar. Clicks go through to the title bar underneath,
    /// so dragging and double-click to zoom behave as before.
    final class TitlebarTint: NSView {
        override func draw(_ dirtyRect: NSRect) {
            NSColor.lightTitlebar.setFill()
            bounds.intersection(dirtyRect).fill()
        }

        override func hitTest(_ point: NSPoint) -> NSView? { nil }
    }
}

extension NSColor {
    /// The navigation bar in light mode, a step below the page.
    static let lightChrome = NSColor(srgbRed: 0.855, green: 0.863, blue: 0.878, alpha: 1)
    /// The title bar in light mode: the darkest grey in the palette.
    static let lightTitlebar = NSColor(srgbRed: 0.784, green: 0.792, blue: 0.812, alpha: 1)
}

extension View {
    /// Applies `WindowChrome` to the window this view ends up in.
    func solidTitleBar() -> some View {
        background(WindowChrome().frame(width: 0, height: 0))
    }
}
