import AppKit
import ServiceManagement
import SwiftUI

/// UI state for the panel, plus the actions the views can trigger.
/// The app delegate fills in the `on…` closures.
final class PanelModel: ObservableObject {
    enum Tab: String, CaseIterable, Identifiable {
        case clipboard
        case cheatSheet

        var id: String { rawValue }

        var title: String {
            switch self {
            case .clipboard: return "Clipboard"
            case .cheatSheet: return "Cheat sheet"
            }
        }
    }

    @Published var tab: Tab = .clipboard
    /// Search text in the Clipboard tab.
    @Published var query = ""
    /// Search text in the Cheat sheet tab.
    @Published var cheatSheetQuery = ""
    /// True when macOS lets us press ⌘V on the user's behalf (Accessibility permission).
    @Published var canDirectPaste = false
    /// Goes up by one every time the panel opens. Views watch it to refocus the search field.
    @Published var openCount = 0
    @Published var launchAtLogin = false

    var onSnipArea: () -> Void = {}
    var onSnipWindow: () -> Void = {}
    var onOpenScreenshotToolbar: () -> Void = {}
    var onPick: (ClipItem) -> Void = { _ in }
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
