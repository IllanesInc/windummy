import Foundation

/// One Windows → Mac translation.
struct Shortcut: Identifiable {
    /// What the user wants to do, in plain words.
    let action: String
    /// The Windows way.
    let windows: String
    /// The Mac way: one or more key combinations.
    let mac: [String]
    /// Word shown between several Mac combinations: "or", "then", "/".
    let joiner: String
    let note: String?

    var id: String { action + "|" + windows }

    init(_ action: String, win windows: String, mac: String..., joiner: String = "or", note: String? = nil) {
        self.action = action
        self.windows = windows
        self.mac = mac
        self.joiner = joiner
        self.note = note
    }

    func matches(_ query: String) -> Bool {
        let haystack = [action, windows, mac.joined(separator: " "), note ?? ""].joined(separator: " ")
        return haystack.localizedCaseInsensitiveContains(query)
    }
}

struct ShortcutGroup: Identifiable {
    let title: String
    /// SF Symbol name.
    let symbol: String
    let shortcuts: [Shortcut]

    var id: String { title }
}

/// The cheat sheet. Add a line here and it shows up in the app, searchable.
///
/// Symbols: ⌘ Command, ⌥ Option, ⌃ Control, ⇧ Shift, ⌫ Delete (Backspace).
enum CheatSheet {
    static let groups: [ShortcutGroup] = [
        ShortcutGroup(title: "The basics", symbol: "sparkles", shortcuts: [
            Shortcut("Copy", win: "Ctrl+C", mac: "⌘C"),
            Shortcut("Paste", win: "Ctrl+V", mac: "⌘V"),
            Shortcut("Cut", win: "Ctrl+X", mac: "⌘X"),
            Shortcut("Undo", win: "Ctrl+Z", mac: "⌘Z"),
            Shortcut("Redo", win: "Ctrl+Y", mac: "⇧⌘Z"),
            Shortcut("Select all", win: "Ctrl+A", mac: "⌘A"),
            Shortcut("Save", win: "Ctrl+S", mac: "⌘S"),
            Shortcut("Find", win: "Ctrl+F", mac: "⌘F"),
            Shortcut("Print", win: "Ctrl+P", mac: "⌘P"),
            Shortcut("Paste without formatting", win: "Ctrl+Shift+V", mac: "⌥⇧⌘V",
                     note: "Some apps, Chrome for one, use ⇧⌘V."),
            Shortcut("Clipboard history", win: "Win+V", mac: "⌃⌥⌘V",
                     note: "This app. Built into macOS 26 and later: ⌘Space, then ⌘4."),
            Shortcut("Emoji picker", win: "Win+.", mac: "⌃⌘Space"),
            Shortcut("Search and launch apps", win: "Win key", mac: "⌘Space",
                     note: "Spotlight. Also does maths and unit conversion."),
            Shortcut("Settings of the app in front", win: "Usually in a menu", mac: "⌘,"),
        ]),

        ShortcutGroup(title: "Windows and apps", symbol: "macwindow.on.rectangle", shortcuts: [
            Shortcut("Switch between apps", win: "Alt+Tab", mac: "⌘Tab"),
            Shortcut("Switch between windows of one app", win: "Alt+Tab", mac: "⌘`",
                     note: "The key above Tab on a US keyboard. On many European layouts it is ⌘<."),
            Shortcut("Close a window or tab", win: "Ctrl+W", mac: "⌘W"),
            Shortcut("Quit the app", win: "Alt+F4", mac: "⌘Q",
                     note: "The red button only closes the window. The app keeps running until you quit it."),
            Shortcut("Minimize a window", win: "Win+↓", mac: "⌘M"),
            Shortcut("Hide the app in front", win: "No direct equivalent", mac: "⌘H"),
            Shortcut("Full screen", win: "F11", mac: "⌃⌘F"),
            Shortcut("Snap a window left or right", win: "Win+← / Win+→", mac: "fn⌃←", "fn⌃→", joiner: "/",
                     note: "macOS 15 and later. No fn key on your keyboard? Drag the window to a screen edge."),
            Shortcut("Maximize a window", win: "Win+↑", mac: "fn⌃F",
                     note: "Fills the screen without going full screen. macOS 15 and later."),
            Shortcut("See all open windows", win: "Win+Tab", mac: "⌃↑",
                     note: "Mission Control."),
            Shortcut("Show the desktop", win: "Win+D", mac: "F11",
                     note: "fn+F11 on keyboards where the F-keys control brightness and volume."),
            Shortcut("Lock the screen", win: "Win+L", mac: "⌃⌘Q"),
            Shortcut("Force quit a frozen app", win: "Ctrl+Shift+Esc", mac: "⌥⌘Esc",
                     note: "The closest thing to Task Manager is the Activity Monitor app."),
        ]),

        ShortcutGroup(title: "Screenshots", symbol: "camera.viewfinder", shortcuts: [
            Shortcut("Snip an area to the clipboard", win: "Win+Shift+S", mac: "⌃⌥⌘S",
                     note: "This app. Built into macOS: ⌃⇧⌘4."),
            Shortcut("Snip an area to a file", win: "Win+Shift+S, then save", mac: "⇧⌘4",
                     note: "The file lands on the desktop."),
            Shortcut("Capture one window", win: "Alt+PrtScn", mac: "⇧⌘4", "Space", joiner: "then",
                     note: "This app: ⌃⌥⌘W, straight to the clipboard."),
            Shortcut("Capture the whole screen", win: "PrtScn", mac: "⇧⌘3"),
            Shortcut("Screen recording and options", win: "Win+Shift+R", mac: "⇧⌘5"),
        ]),

        ShortcutGroup(title: "Typing and editing", symbol: "character.cursor.ibeam", shortcuts: [
            Shortcut("Start or end of the line", win: "Home / End", mac: "⌘←", "⌘→", joiner: "/"),
            Shortcut("Start or end of the document", win: "Ctrl+Home / Ctrl+End", mac: "⌘↑", "⌘↓", joiner: "/"),
            Shortcut("Jump one word", win: "Ctrl+← / Ctrl+→", mac: "⌥←", "⌥→", joiner: "/"),
            Shortcut("Delete the previous word", win: "Ctrl+Backspace", mac: "⌥⌫"),
            Shortcut("Delete forward", win: "Delete", mac: "fn⌫",
                     note: "Full-size keyboards have a real forward-delete key that works as on Windows."),
            Shortcut("Delete back to the start of the line", win: "No direct equivalent", mac: "⌘⌫"),
        ]),

        ShortcutGroup(title: "Finder (File Explorer)", symbol: "folder", shortcuts: [
            Shortcut("Rename a file", win: "F2", mac: "Return"),
            Shortcut("Open a file or folder", win: "Enter", mac: "⌘O", "⌘↓"),
            Shortcut("Move to the Trash", win: "Delete", mac: "⌘⌫"),
            Shortcut("Delete permanently", win: "Shift+Delete", mac: "⌥⌘⌫"),
            Shortcut("Move files (cut and paste)", win: "Ctrl+X, then Ctrl+V", mac: "⌘C", "⌥⌘V", joiner: "then"),
            Shortcut("Properties", win: "Alt+Enter", mac: "⌘I",
                     note: "Called Get Info on the Mac."),
            Shortcut("New folder", win: "Ctrl+Shift+N", mac: "⇧⌘N"),
            Shortcut("Go up one folder", win: "Alt+↑", mac: "⌘↑"),
            Shortcut("Go back", win: "Alt+←", mac: "⌘["),
            Shortcut("Type a path", win: "Ctrl+L", mac: "⇧⌘G",
                     note: "Go to Folder."),
            Shortcut("Show hidden files", win: "View menu, Hidden items", mac: "⇧⌘."),
            Shortcut("Preview without opening", win: "No direct equivalent", mac: "Space",
                     note: "Quick Look. Works on almost any file."),
        ]),

        ShortcutGroup(title: "Browser", symbol: "globe", shortcuts: [
            Shortcut("Address bar", win: "Ctrl+L", mac: "⌘L"),
            Shortcut("New tab", win: "Ctrl+T", mac: "⌘T"),
            Shortcut("Reopen a closed tab", win: "Ctrl+Shift+T", mac: "⇧⌘T"),
            Shortcut("Next or previous tab", win: "Ctrl+Tab / Ctrl+Shift+Tab", mac: "⌃Tab", "⌃⇧Tab", joiner: "/",
                     note: "The same keys as on Windows."),
            Shortcut("Reload", win: "F5", mac: "⌘R"),
            Shortcut("Reload ignoring the cache", win: "Ctrl+F5", mac: "⇧⌘R",
                     note: "Chrome, Edge and Firefox. In Safari it is ⌥⌘R."),
            Shortcut("Developer tools", win: "F12", mac: "⌥⌘I"),
        ]),

        ShortcutGroup(title: "Terminal", symbol: "terminal", shortcuts: [
            Shortcut("Stop a running command", win: "Ctrl+C", mac: "⌃C",
                     note: "Control keeps its terminal meaning on the Mac, so it never clashes with copy."),
            Shortcut("Copy or paste in the terminal", win: "Ctrl+Shift+C / Ctrl+Shift+V", mac: "⌘C", "⌘V", joiner: "/"),
            Shortcut("Clear the screen", win: "cls", mac: "⌘K"),
            Shortcut("Install software from the command line", win: "winget install", mac: "brew install",
                     note: "Homebrew, from brew.sh."),
        ]),
    ]
}
