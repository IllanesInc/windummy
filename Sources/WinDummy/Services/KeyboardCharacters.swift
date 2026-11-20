import AppKit
import Carbon

/// How to type one character on the current keyboard layout.
struct KeyRecipe: Equatable {
    /// One or more key combinations, pressed one after the other.
    /// Two steps means a dead key: press the first, let go, then the second.
    let steps: [String]

    var isDeadKey: Bool { steps.count > 1 }
}

/// Works out where special characters sit on the keyboard layout in use, and
/// remembers the user's favourite characters.
///
/// Instead of a hand-written table per country, it asks macOS what every key
/// produces with no modifier, ⇧, ⌥ and ⌥⇧ (`UCKeyTranslate`). That way the
/// answers are right for any layout, and they follow along when the user
/// switches layouts.
final class KeyboardCharacters: ObservableObject {
    /// Localised name of the layout, for example "Swedish – Pro".
    @Published private(set) var layoutName = ""
    @Published private(set) var recipes: [String: KeyRecipe] = [:]
    /// Characters the user starred, in the order they were added.
    @Published private(set) var favorites: [String]

    private static let favoritesKey = "favoriteCharacters"

    init() {
        favorites = UserDefaults.standard.stringArray(forKey: Self.favoritesKey) ?? []
        refresh()

        // Fires when the user picks another layout from the input menu.
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refresh()
        }
    }

    // MARK: - Favourites

    func isFavorite(_ character: String) -> Bool {
        favorites.contains(character)
    }

    func toggleFavorite(_ character: String) {
        if let index = favorites.firstIndex(of: character) {
            favorites.remove(at: index)
        } else {
            favorites.append(character)
        }
        UserDefaults.standard.set(favorites, forKey: Self.favoritesKey)
    }

    // MARK: - Layout

    func refresh() {
        guard let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue() else { return }

        if let pointer = TISGetInputSourceProperty(source, kTISPropertyLocalizedName) {
            layoutName = Unmanaged<CFString>.fromOpaque(pointer).takeUnretainedValue() as String
        }

        guard let pointer = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
            recipes = [:]
            return
        }
        let data = Unmanaged<CFData>.fromOpaque(pointer).takeUnretainedValue() as Data
        let wanted = Set(Characters.all.map(\.character))

        recipes = data.withUnsafeBytes { raw -> [String: KeyRecipe] in
            guard let base = raw.baseAddress else { return [:] }
            let layout = base.assumingMemoryBound(to: UCKeyboardLayout.self)
            return Self.findRecipes(for: wanted, in: layout)
        }
    }

    /// Modifier combinations to try, simplest first.
    private static let modifierSets: [(carbon: Int, symbols: String)] = [
        (0, ""),
        (shiftKey, "⇧"),
        (optionKey, "⌥"),
        (optionKey | shiftKey, "⌥⇧"),
    ]

    /// The keys of the main block that type characters. Leaves out Return,
    /// Tab, Space, Delete, Esc and everything from the function keys and the
    /// numeric keypad onwards.
    private static let characterKeyCodes: [UInt16] = (0..<64).map(UInt16.init).filter {
        ![kVK_Return, kVK_Tab, kVK_Space, kVK_Delete, kVK_Escape].contains(Int($0))
    }

    private static func findRecipes(for wanted: Set<String>, in layout: UnsafePointer<UCKeyboardLayout>) -> [String: KeyRecipe] {
        var found: [String: KeyRecipe] = [:]
        var deadKeys: [(keyCode: UInt16, modifiers: Int, symbols: String)] = []

        // First pass: a single key press. Simpler combinations win because
        // they are tried first.
        for (modifiers, symbols) in modifierSets {
            for keyCode in characterKeyCodes {
                var deadState: UInt32 = 0
                let output = translate(layout, keyCode: keyCode, modifiers: modifiers, deadState: &deadState)

                if output.isEmpty, deadState != 0 {
                    deadKeys.append((keyCode, modifiers, symbols))
                    continue
                }
                guard wanted.contains(output), found[output] == nil, let label = keyLabel(layout, keyCode: keyCode) else {
                    continue
                }
                found[output] = KeyRecipe(steps: [symbols + label])
            }
        }

        // Second pass: dead keys. On many European layouts ~ ^ and ` are
        // typed by pressing an accent key and then Space.
        for (keyCode, modifiers, symbols) in deadKeys {
            var deadState: UInt32 = 0
            _ = translate(layout, keyCode: keyCode, modifiers: modifiers, deadState: &deadState)
            let output = translate(layout, keyCode: UInt16(kVK_Space), modifiers: 0, deadState: &deadState)

            guard wanted.contains(output), found[output] == nil, let label = keyLabel(layout, keyCode: keyCode) else {
                continue
            }
            found[output] = KeyRecipe(steps: [symbols + label, "Space"])
        }

        return found
    }

    /// What is printed on the key: its output with no modifiers and dead keys
    /// turned off, so an accent key shows its accent.
    private static func keyLabel(_ layout: UnsafePointer<UCKeyboardLayout>, keyCode: UInt16) -> String? {
        var deadState: UInt32 = 0
        let output = translate(layout, keyCode: keyCode, modifiers: 0, deadState: &deadState,
                               options: OptionBits(kUCKeyTranslateNoDeadKeysMask))
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines.union(.controlCharacters))
        return trimmed.isEmpty ? nil : trimmed.uppercased()
    }

    private static func translate(
        _ layout: UnsafePointer<UCKeyboardLayout>,
        keyCode: UInt16,
        modifiers: Int,
        deadState: inout UInt32,
        options: OptionBits = 0
    ) -> String {
        var length = 0
        var characters = [UniChar](repeating: 0, count: 4)
        let status = UCKeyTranslate(
            layout,
            keyCode,
            UInt16(kUCKeyActionDown),
            UInt32((modifiers >> 8) & 0xFF),
            UInt32(LMGetKbdType()),
            options,
            &deadState,
            characters.count,
            &length,
            &characters
        )
        guard status == noErr else { return "" }
        return String(utf16CodeUnits: characters, count: length)
    }
}
