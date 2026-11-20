import SwiftUI

/// Where to find @, |, \, { } and friends on the keyboard in use.
/// Click a character to type it, star it to keep it at the top.
struct CharactersView: View {
    @EnvironmentObject private var model: PanelModel
    @EnvironmentObject private var keyboard: KeyboardCharacters
    @FocusState private var searchFocused: Bool

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    private var filtered: [SpecialCharacter] {
        let query = model.charactersQuery.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return Characters.all }
        return Characters.all.filter { $0.matches(query) }
    }

    private var favorites: [SpecialCharacter] {
        keyboard.favorites.compactMap { favorite in
            filtered.first { $0.character == favorite }
        }
    }

    private var others: [SpecialCharacter] {
        filtered.filter { !keyboard.isFavorite($0.character) }
    }

    var body: some View {
        VStack(spacing: 8) {
            SearchField(text: $model.charactersQuery, prompt: "Search, for example “@” or “pipe”", focused: $searchFocused)

            if filtered.isEmpty {
                EmptyState(
                    symbol: "character",
                    title: "No matches",
                    message: "Try the character itself, like “|”,\nor its name, like “backslash”."
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if model.charactersQuery.isEmpty {
                            LayoutInfo()
                        }
                        if !favorites.isEmpty {
                            section("Favorites", symbol: "star.fill", characters: favorites)
                        }
                        if !others.isEmpty {
                            section(favorites.isEmpty ? "Characters" : "All characters",
                                    symbol: "character.cursor.ibeam", characters: others)
                        }
                    }
                    .padding(.horizontal, Theme.sidePadding)
                    .padding(.bottom, 12)
                }
            }
        }
        .onAppear {
            searchFocused = true
        }
        .onChange(of: model.openCount) { _, _ in
            searchFocused = true
        }
    }

    private func section(_ title: String, symbol: String, characters: [SpecialCharacter]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(characters) { character in
                    CharacterTile(character: character)
                }
            }
        }
    }
}

private struct LayoutInfo: View {
    @EnvironmentObject private var model: PanelModel
    @EnvironmentObject private var keyboard: KeyboardCharacters

    private var hasDeadKeys: Bool {
        keyboard.recipes.values.contains(where: \.isDeadKey)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(keyboard.layoutName.isEmpty ? "Your keyboard" : keyboard.layoutName, systemImage: "keyboard")
                .font(.system(size: 12, weight: .semibold))
            Text("AltGr on Windows is ⌥ Option on the Mac. Star a character to keep it at the top.")
            if model.canDirectPaste {
                Text("Click a character to type it where your cursor is.")
            } else {
                Text("Click a character to copy it, then press ⌘V. Turn on direct paste below and it is typed for you.")
            }
            if hasDeadKeys {
                Text("Two keys means: press the first, let go, then press the second.")
            }
        }
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .card()
    }
}

private struct CharacterTile: View {
    let character: SpecialCharacter

    @EnvironmentObject private var model: PanelModel
    @EnvironmentObject private var keyboard: KeyboardCharacters
    @EnvironmentObject private var hover: HoverTracker

    private var hoverID: String { "char-" + character.character }
    private var isHovered: Bool { hover.hoveredID == hoverID }
    private var isFavorite: Bool { keyboard.isFavorite(character.character) }

    var body: some View {
        Button {
            model.onTypeCharacter(character.character)
        } label: {
            VStack(spacing: 6) {
                Text(verbatim: character.character)
                    .font(.system(size: 24, weight: .medium))
                    .frame(height: 30)

                if let recipe = keyboard.recipes[character.character] {
                    HStack(spacing: 3) {
                        ForEach(Array(recipe.steps.enumerated()), id: \.offset) { _, step in
                            KeyCap(step, compact: true)
                        }
                    }
                } else {
                    Text("Not on this keyboard")
                        .font(.system(size: 9.5))
                        .foregroundStyle(.tertiary)
                        .frame(height: 19)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.primary.opacity(isHovered ? 0.11 : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        // The star sits in the corner: always shown on favourites, on hover for the rest.
        .overlay(alignment: .topTrailing) {
            if isHovered || isFavorite {
                Button {
                    keyboard.toggleFavorite(character.character)
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.system(size: 11))
                        .foregroundStyle(isFavorite ? Color.yellow : Color.secondary)
                        .padding(6)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(isFavorite ? "Remove from favorites" : "Add to favorites")
            }
        }
        .contextMenu {
            Button(isFavorite ? "Remove from favorites" : "Add to favorites") {
                keyboard.toggleFavorite(character.character)
            }
            Button("Copy") {
                model.onCopyCharacter(character.character)
            }
        }
        .onHover { isHovering in
            hover.update(hoverID, isHovering: isHovering)
        }
        .help(character.name)
    }
}
