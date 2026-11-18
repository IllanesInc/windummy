import AppKit

/// A panel that can take keyboard focus without activating the app.
///
/// That detail is what makes "pick a clip, paste it" work: the app you were
/// typing in stays the active app the whole time, so a ⌘V sent right after the
/// panel closes lands exactly where your cursor was.
final class FloatingPanel: NSPanel {
    /// Called when the panel should go away: Esc, or focus moved elsewhere.
    var onDismiss: (() -> Void)?

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        // Same level as menus, so notification banners cannot cover the panel.
        level = .popUpMenu
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Keep the title bar (it gives us the system's rounded corners and shadow)
        // but make it invisible so the SwiftUI content fills the whole window.
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true

        isOpaque = false
        backgroundColor = .clear
        hasShadow = true

        // The app is never "active" (it has no Dock icon), so the default
        // hide-on-deactivate behaviour would hide the panel immediately.
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        isMovableByWindowBackground = true
        animationBehavior = .utilityWindow
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    /// Esc.
    override func cancelOperation(_ sender: Any?) {
        onDismiss?()
    }

    /// Clicked in another window or app.
    override func resignKey() {
        super.resignKey()
        onDismiss?()
    }

    override func resignMain() {
        super.resignMain()
        onDismiss?()
    }
}
