import AppKit
import SwiftUI

/// Owns the menu bar icon, the floating panel and the global hotkeys.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: FloatingPanel!

    private let clipboard = ClipboardStore()
    private let model = PanelModel()
    private let hover = HoverTracker()
    private let keyboard = KeyboardCharacters()

    private var isHiding = false
    private var lastHide = Date.distantPast

    // MARK: - Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        setUpStatusItem()
        setUpPanel()
        setUpHotKeys()
        clipboard.start()
    }

    // MARK: - Menu bar icon

    private func setUpStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem.button else { return }

        if let image = NSImage(systemSymbolName: "command", accessibilityDescription: "WinDummy") {
            image.isTemplate = true
            button.image = image
        } else {
            button.title = "⌘"
        }
        button.toolTip = "WinDummy (⌃⌥⌘V)"
        button.target = self
        button.action = #selector(statusItemClicked)
    }

    @objc private func statusItemClicked() {
        togglePanel(fromStatusItem: true)
    }

    // MARK: - Panel

    private func setUpPanel() {
        panel = FloatingPanel(contentRect: NSRect(origin: .zero, size: Theme.panelSize))
        panel.onDismiss = { [weak self] in self?.hidePanel() }

        model.onSnipArea = { [weak self] in
            self?.closeThen { ScreenCapture.snipAreaToClipboard() }
        }
        model.onSnipWindow = { [weak self] in
            self?.closeThen { ScreenCapture.snipWindowToClipboard() }
        }
        model.onOpenScreenshotToolbar = { [weak self] in
            self?.closeThen { ScreenCapture.openScreenshotToolbar() }
        }
        model.onPick = { [weak self] item, plainText in
            self?.pick(item, plainText: plainText)
        }
        model.onTypeCharacter = { [weak self] character in
            self?.type(character)
        }
        model.onCopyCharacter = { [weak self] character in
            self?.hidePanel()
            Self.putOnClipboard(character)
        }
        model.onEnableDirectPaste = { [weak self] in
            self?.hidePanel()
            Paster.requestPermission()
        }
        model.onClearHistory = { [weak self] in
            self?.clipboard.clear()
        }
        model.onClose = { [weak self] in
            self?.hidePanel()
        }
        model.onQuit = {
            NSApp.terminate(nil)
        }

        let root = PanelView()
            .environmentObject(model)
            .environmentObject(clipboard)
            .environmentObject(hover)
            .environmentObject(keyboard)
        panel.contentView = NSHostingView(rootView: root)
    }

    private func togglePanel(fromStatusItem: Bool) {
        if panel.isVisible {
            hidePanel()
            return
        }
        // Clicking the menu bar icon while the panel is open first dismisses the
        // panel (it loses focus) and then delivers the click. Without this guard
        // that click would immediately reopen it.
        if fromStatusItem, Date().timeIntervalSince(lastHide) < 0.3 {
            return
        }
        showPanel(nearStatusItem: fromStatusItem)
    }

    private func showPanel(nearStatusItem: Bool) {
        model.canDirectPaste = Paster.isTrusted
        model.query = ""
        model.charactersQuery = ""
        keyboard.refresh()
        hover.clear()
        positionPanel(nearStatusItem: nearStatusItem)

        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            self.panel.animator().alphaValue = 1
        }
        model.openCount += 1
    }

    private func hidePanel() {
        guard panel.isVisible, !isHiding else { return }
        isHiding = true
        lastHide = Date()
        panel.orderOut(nil)
        isHiding = false
    }

    /// Under the menu bar icon when clicked, around the mouse pointer when opened by hotkey.
    private func positionPanel(nearStatusItem: Bool) {
        let size = panel.frame.size
        let mouse = NSEvent.mouseLocation
        var origin = NSPoint(x: mouse.x - size.width / 2, y: mouse.y - size.height + 60)

        if nearStatusItem, let button = statusItem.button, let buttonWindow = button.window {
            let buttonFrame = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
            origin = NSPoint(x: buttonFrame.midX - size.width / 2, y: buttonFrame.minY - size.height - 6)
        }

        let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) }) ?? NSScreen.main
        if let visible = screen?.visibleFrame.insetBy(dx: 8, dy: 8) {
            origin.x = min(max(origin.x, visible.minX), visible.maxX - size.width)
            origin.y = min(max(origin.y, visible.minY), visible.maxY - size.height)
        }
        panel.setFrameOrigin(origin)
    }

    // MARK: - Actions

    /// Hides the panel first so it never ends up in the screenshot, then runs `action`.
    private func closeThen(_ action: @escaping () -> Void) {
        guard panel.isVisible else {
            action()
            return
        }
        hidePanel()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            action()
        }
    }

    private func pick(_ item: ClipItem, plainText: Bool) {
        clipboard.copyToClipboard(item, plainText: plainText)
        hidePanel()
        // With Accessibility permission we can press ⌘V for the user, like Win+V does.
        // Without it the item is simply on the clipboard, ready for a manual ⌘V.
        if Paster.isTrusted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                Paster.paste()
            }
        }
    }

    /// Pastes the character where the cursor is, leaving the clipboard as it was.
    /// Without the Accessibility permission it goes on the clipboard instead, ready for ⌘V.
    private func type(_ character: String) {
        hidePanel()
        if Paster.isTrusted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.clipboard.pasteTemporarily(character) {
                    Paster.paste()
                }
            }
        } else {
            Self.putOnClipboard(character)
        }
    }

    private static func putOnClipboard(_ string: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }

    // MARK: - Global hotkeys (⌃⌥⌘ + letter)

    private func setUpHotKeys() {
        let center = HotKeyCenter.shared
        let bindings: [(key: HotKeyCenter.Key, action: () -> Void)] = [
            (.v, { [weak self] in self?.togglePanel(fromStatusItem: false) }),
            (.s, { [weak self] in self?.closeThen { ScreenCapture.snipAreaToClipboard() } }),
            (.w, { [weak self] in self?.closeThen { ScreenCapture.snipWindowToClipboard() } }),
        ]
        // A combination another app already uses cannot be registered.
        // Tell the user instead of leaving the key silently dead.
        model.unavailableHotKeys = bindings
            .filter { !center.register($0.key, handler: $0.action) }
            .map { "⌃⌥⌘" + $0.key.letter }
    }
}
