import Foundation

/// A character that is hard to find on a Mac keyboard.
struct SpecialCharacter: Identifiable {
    let character: String
    /// What it is called, in English.
    let name: String
    /// Other words people search for, in any language.
    let aliases: [String]

    var id: String { character }

    init(_ character: String, _ name: String, aliases: [String] = []) {
        self.character = character
        self.name = name
        self.aliases = aliases
    }

    func matches(_ query: String) -> Bool {
        if character == query {
            return true
        }
        return ([name] + aliases).contains { $0.localizedCaseInsensitiveContains(query) }
    }
}

/// The characters shown in the Characters tab. Where each one sits on the
/// keyboard is worked out from the current layout, see `KeyboardCharacters`.
/// Add a line here and it shows up in the app.
enum Characters {
    static let all: [SpecialCharacter] = [
        SpecialCharacter("@", "At sign", aliases: ["at", "email", "snabel-a", "arroba"]),
        SpecialCharacter("|", "Vertical bar", aliases: ["pipe", "rör", "lodstreck"]),
        SpecialCharacter("\\", "Backslash", aliases: ["omvänt snedstreck", "bakstreck"]),
        SpecialCharacter("/", "Slash", aliases: ["snedstreck", "divided"]),
        SpecialCharacter("{", "Left brace", aliases: ["curly bracket", "krullparentes", "måsvinge"]),
        SpecialCharacter("}", "Right brace", aliases: ["curly bracket", "krullparentes", "måsvinge"]),
        SpecialCharacter("[", "Left bracket", aliases: ["square bracket", "hakparentes"]),
        SpecialCharacter("]", "Right bracket", aliases: ["square bracket", "hakparentes"]),
        SpecialCharacter("<", "Less than", aliases: ["mindre än", "angle bracket"]),
        SpecialCharacter(">", "Greater than", aliases: ["större än", "angle bracket"]),
        SpecialCharacter("~", "Tilde", aliases: ["tilde", "home"]),
        SpecialCharacter("`", "Backtick", aliases: ["grave accent", "accent grave", "code"]),
        SpecialCharacter("^", "Caret", aliases: ["circumflex", "hatt", "power"]),
        SpecialCharacter("$", "Dollar", aliases: ["dollar"]),
        SpecialCharacter("€", "Euro", aliases: ["euro", "currency", "valuta"]),
        SpecialCharacter("£", "Pound", aliases: ["pund", "sterling", "currency"]),
        SpecialCharacter("#", "Hash", aliases: ["number sign", "hashtag", "brädgård", "fyrkant"]),
        SpecialCharacter("&", "Ampersand", aliases: ["and", "och", "et-tecken"]),
        SpecialCharacter("*", "Asterisk", aliases: ["star", "stjärna", "multiply"]),
        SpecialCharacter("%", "Percent", aliases: ["procent"]),
        SpecialCharacter("=", "Equals", aliases: ["lika med"]),
        SpecialCharacter("+", "Plus", aliases: ["plus"]),
        SpecialCharacter("_", "Underscore", aliases: ["understreck"]),
        SpecialCharacter("\"", "Double quote", aliases: ["citattecken", "quotation"]),
        SpecialCharacter("'", "Apostrophe", aliases: ["single quote", "apostrof"]),
        SpecialCharacter("§", "Section sign", aliases: ["paragraf", "paragraph"]),
        SpecialCharacter("°", "Degree", aliases: ["grader", "temperature"]),
        SpecialCharacter("±", "Plus-minus", aliases: ["plus minus"]),
        SpecialCharacter("≠", "Not equal", aliases: ["inte lika med"]),
        SpecialCharacter("×", "Multiplication sign", aliases: ["times", "gånger"]),
        SpecialCharacter("÷", "Division sign", aliases: ["divide", "delat"]),
        SpecialCharacter("–", "En dash", aliases: ["tankstreck", "dash"]),
        SpecialCharacter("—", "Em dash", aliases: ["dash"]),
        SpecialCharacter("…", "Ellipsis", aliases: ["three dots", "tre punkter"]),
        SpecialCharacter("•", "Bullet", aliases: ["punkt", "dot"]),
        SpecialCharacter("©", "Copyright", aliases: ["copyright"]),
        SpecialCharacter("®", "Registered", aliases: ["registered trademark"]),
        SpecialCharacter("™", "Trademark", aliases: ["varumärke"]),
    ]
}
