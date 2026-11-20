import Carbon
import Testing
@testable import WinDummy

/// Checks the key combinations against fixed layouts, whatever layout the
/// machine running the tests happens to use.
///
/// On the main actor because the Text Input Sources API crashes on purpose
/// when called from any other thread.
@MainActor
@Suite struct KeyboardCharactersTests {
    private func recipes(layout id: String) throws -> [String: KeyRecipe] {
        let filter = [kTISPropertyInputSourceID as String: id] as CFDictionary
        let sources = TISCreateInputSourceList(filter, true)?.takeRetainedValue() as? [TISInputSource]
        let source = try #require(sources?.first, "layout \(id) is not installed")
        return KeyboardCharacters.recipes(for: source)
    }

    @Test func swedishPro() throws {
        let recipes = try recipes(layout: "com.apple.keylayout.Swedish-Pro")
        #expect(recipes["@"]?.steps == ["⌥2"])
        #expect(recipes["|"]?.steps == ["⌥7"])
        #expect(recipes["\\"]?.steps == ["⌥⇧7"])
        #expect(recipes["{"]?.steps == ["⌥⇧8"])
        #expect(recipes["["]?.steps == ["⌥8"])
        #expect(recipes["$"]?.steps == ["⌥4"])
        #expect(recipes["~"]?.steps == ["⌥¨", "Space"])
    }

    @Test func us() throws {
        let recipes = try recipes(layout: "com.apple.keylayout.US")
        #expect(recipes["@"]?.steps == ["⇧2"])
        #expect(recipes["|"]?.steps == ["⇧\\"])
        #expect(recipes["\\"]?.steps == ["\\"])
        #expect(recipes["{"]?.steps == ["⇧["])
        #expect(recipes["€"]?.steps == ["⌥⇧2"])
    }
}
