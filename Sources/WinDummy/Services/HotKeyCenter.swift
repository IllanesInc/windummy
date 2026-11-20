import AppKit
import Carbon

/// Global hotkeys through Carbon's `RegisterEventHotKey`.
///
/// The API is ancient, but it is still the only way to get a system-wide hotkey
/// that needs no Accessibility permission and swallows the key press, so the
/// app in front never sees it.
final class HotKeyCenter {
    static let shared = HotKeyCenter()

    /// The keys this app binds. Each is combined with ⌃⌥⌘, the three keys in the
    /// bottom-left corner of the keyboard. The letters match the Windows
    /// shortcuts they replace: Win+Shift+**S**, Win+**V**.
    enum Key {
        case s
        case v
        case w

        var letter: String {
            switch self {
            case .s: return "S"
            case .v: return "V"
            case .w: return "W"
            }
        }

        var keyCode: Int {
            switch self {
            case .s: return kVK_ANSI_S
            case .v: return kVK_ANSI_V
            case .w: return kVK_ANSI_W
            }
        }
    }

    private static let signature: OSType = 0x5744_4D59 // "WDMY"

    private var handlers: [UInt32: () -> Void] = [:]
    private var references: [EventHotKeyRef] = []
    private var nextID: UInt32 = 1
    private var handlerInstalled = false

    private init() {}

    /// Registers ⌃⌥⌘ + `key`. Returns `false` if the combination is already taken.
    @discardableResult
    func register(_ key: Key, handler: @escaping () -> Void) -> Bool {
        installHandlerIfNeeded()

        let id = nextID
        nextID += 1

        var reference: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: HotKeyCenter.signature, id: id)
        let modifiers = UInt32(controlKey | optionKey | cmdKey)
        let status = RegisterEventHotKey(
            UInt32(key.keyCode),
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &reference
        )

        guard status == noErr, let reference = reference else {
            NSLog("WinDummy: could not register a hotkey (status \(status))")
            return false
        }
        handlers[id] = handler
        references.append(reference)
        return true
    }

    fileprivate func fire(_ id: UInt32) {
        handlers[id]?()
    }

    private func installHandlerIfNeeded() {
        guard !handlerInstalled else { return }
        handlerInstalled = true

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(GetApplicationEventTarget(), hotKeyEventHandler, 1, &eventType, nil, nil)
    }
}

/// C callback: Carbon calls this on the main thread whenever a registered hotkey is pressed.
private func hotKeyEventHandler(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )
    guard status == noErr else { return status }

    let id = hotKeyID.id
    DispatchQueue.main.async {
        HotKeyCenter.shared.fire(id)
    }
    return OSStatus(noErr)
}
