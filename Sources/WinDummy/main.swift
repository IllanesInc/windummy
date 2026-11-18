import AppKit

// WinDummy lives in the menu bar only: no Dock icon, no main window.
// The entry point is plain AppKit; the panel's content is SwiftUI.

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
