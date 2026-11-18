import AppKit

/// Thin wrapper around macOS's own `screencapture` tool.
///
/// Flags used: `-i` interactive, `-s` area selection only, `-w` window selection
/// only, `-o` leave out the window shadow, `-c` put the result on the clipboard
/// instead of saving a file.
enum ScreenCapture {
    /// Drag out an area; it lands on the clipboard. (Windows: Win+Shift+S)
    static func snipAreaToClipboard() {
        run(["-i", "-s", "-c"])
    }

    /// Click a window; it lands on the clipboard. (Windows: Alt+PrtScn)
    static func snipWindowToClipboard() {
        run(["-i", "-w", "-o", "-c"])
    }

    /// Opens the system screenshot toolbar (⇧⌘5): screen recording, timer, save options.
    static func openScreenshotToolbar() {
        let url = URL(fileURLWithPath: "/System/Applications/Utilities/Screenshot.app")
        NSWorkspace.shared.open(url)
    }

    private static func run(_ arguments: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = arguments
        do {
            try process.run()
        } catch {
            NSLog("WinDummy: could not start screencapture: \(error.localizedDescription)")
        }
    }
}
