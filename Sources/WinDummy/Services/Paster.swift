import AppKit

/// Presses ⌘V on the user's behalf, so picking a clip pastes it straight away
/// (the way Win+V behaves on Windows).
///
/// Sending key presses to other apps needs the Accessibility permission. It is
/// optional: without it, a picked clip is put on the clipboard and the user
/// presses ⌘V themselves.
enum Paster {
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Shows the system prompt that leads to System Settings → Privacy & Security → Accessibility.
    static func requestPermission() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    static func paste() {
        let keyV: CGKeyCode = 9 // the physical V key (kVK_ANSI_V)
        let source = CGEventSource(stateID: .combinedSessionState)

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyV, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyV, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
