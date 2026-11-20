import AppKit
import ServiceManagement
import SwiftUI

/// UI state for the panel, plus the actions the views can trigger.
/// The app delegate fills in the `on…` closures.
final class PanelModel: ObservableObject {
    enum Tab: String, CaseIterable, Identifiable {
        case clipboard
        case characters
        case cheatSheet

        var id: String { rawValue }

        var title: String {
            switch self {
            case .clipboard: return "Clipboard"
            case .characters: return "Characters"
            case .cheatSheet: return "Cheat sheet"
            }
        }
    }

    @Published var tab: Tab = .clipboard
    /// Search text in the Clipboard tab.
    @Published var query = ""
    /// Search text in the Cheat sheet tab.
    @Published var cheatSheetQuery = ""
    /// Search text in the Characters tab.
    @Published var charactersQuery = ""
    /// True when macOS lets us press ⌘V on the user's behalf (Accessibility permission).
    @Published var canDirectPaste = false
    /// Goes up by one every time the panel opens. Views watch it to refocus the search field.
    @Published var openCount = 0
    @Published var launchAtLogin = false
    /// Our hotkeys that another app had already taken, for example "⌃⌥⌘S".
    @Published var unavailableHotKeys: [String] = []

    var onSnipArea: () -> Void = {}
    var onSnipWindow: () -> Void = {}
    var onOpenScreenshotToolbar: () -> Void = {}
    /// Pastes a history entry. The flag asks for plain text (⌥ held).
    var onPick: (ClipItem, _ plainText: Bool) -> Void = { _, _ in }
    /// Puts a character into the app the user was working in.
    var onTypeCharacter: (String) -> Void = { _ in }
    var onCopyCharacter: (String) -> Void = { _ in }
    var onEnableDirectPaste: () -> Void = {}
    var onClearHistory: () -> Void = {}
    var onClose: () -> Void = {}
    var onQuit: () -> Void = {}

    init() {
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("WinDummy: could not change launch at login: \(error.localizedDescription)")
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }
}
