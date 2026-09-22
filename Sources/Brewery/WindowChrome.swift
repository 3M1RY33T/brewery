import AppKit
import SwiftUI

/// Keeps the title bar a solid band above everything else.
///
/// SwiftUI's window group makes the title bar transparent and lets the
/// sidebar run up behind it, so the window title ends up cramped inside the
/// navigation column. This turns that off once the view has a window: the
/// title bar is opaque, ends in a hairline, and the sidebar starts below it.
struct WindowChrome: NSViewRepresentable {
    func makeNSView(context: Context) -> ChromeView { ChromeView() }
    func updateNSView(_ nsView: ChromeView, context: Context) {}

    final class ChromeView: NSView {
        private var observer: NSObjectProtocol?

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

        private func apply(to window: NSWindow) {
            window.styleMask.remove(.fullSizeContentView)
            window.titlebarAppearsTransparent = false
            window.titlebarSeparatorStyle = .line
            window.titleVisibility = .visible
        }

        deinit {
            if let observer { NotificationCenter.default.removeObserver(observer) }
        }
    }
}

extension View {
    /// Applies `WindowChrome` to the window this view ends up in.
    func solidTitleBar() -> some View {
        background(WindowChrome().frame(width: 0, height: 0))
    }
}
