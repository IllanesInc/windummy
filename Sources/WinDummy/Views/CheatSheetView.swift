import SwiftUI

/// Searchable Windows → Mac shortcut translations.
struct CheatSheetView: View {
    @EnvironmentObject private var model: PanelModel
    @FocusState private var searchFocused: Bool

    private var filteredGroups: [ShortcutGroup] {
        let trimmed = model.cheatSheetQuery.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return CheatSheet.groups }
        return CheatSheet.groups.compactMap { group -> ShortcutGroup? in
            let matches = group.shortcuts.filter { $0.matches(trimmed) }
            if matches.isEmpty {
                return nil
            }
            return ShortcutGroup(title: group.title, symbol: group.symbol, shortcuts: matches)
        }
    }

    /// Searching for "@" or "pipe" here should not end in "No matches":
    /// those answers live in the Characters tab, so show them right here.
    private var matchingCharacters: [SpecialCharacter] {
        let trimmed = model.cheatSheetQuery.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        return Array(Characters.all.filter { $0.matches(trimmed) }.prefix(3))
    }

    var body: some View {
        VStack(spacing: 8) {
            SearchField(text: $model.cheatSheetQuery, prompt: "Search, for example “rename” or “Alt+Tab”", focused: $searchFocused)

            if filteredGroups.isEmpty, !matchingCharacters.isEmpty {
                ScrollView {
                    CharacterHints(characters: matchingCharacters)
                        .padding(.horizontal, Theme.sidePadding)
                }
            } else if filteredGroups.isEmpty {
                EmptyState(
                    symbol: "keyboard",
                    title: "No matches",
                    message: "Try the Windows shortcut, like “Win+L”,\nor what you want to do, like “lock”."
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        if model.cheatSheetQuery.isEmpty {
                            KeyLegend()
                        }
                        if !matchingCharacters.isEmpty {
                            CharacterHints(characters: matchingCharacters)
                        }
                        ForEach(filteredGroups) { group in
                            GroupSection(group: group)
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
}

private struct CharacterHints: View {
    let characters: [SpecialCharacter]

    @EnvironmentObject private var model: PanelModel
    @EnvironmentObject private var keyboard: KeyboardCharacters

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("On your keyboard", systemImage: "keyboard")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                ForEach(Array(characters.enumerated()), id: \.element.id) { index, character in
                    if index > 0 {
                        Divider()
                            .padding(.leading, 12)
                    }
                    HStack(spacing: 10) {
                        Text(verbatim: character.character)
                            .font(.system(size: 18, weight: .medium))
                            .frame(width: 26)
                        Text(character.name)
                            .font(.system(size: 12.5, weight: .medium))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if let recipe = keyboard.recipes[character.character] {
                            HStack(spacing: 4) {
                                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                                    if index > 0 {
                                        Text("then")
                                            .font(.system(size: 10.5))
                                            .foregroundStyle(.tertiary)
                                    }
                                    KeyCap(step)
                                }
                            }
                        } else {
                            Text("Not on this keyboard")
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                }
            }
            .card()

            Button("All characters, and click to type them →") {
                model.charactersQuery = model.cheatSheetQuery
                model.tab = .characters
            }
            .buttonStyle(.link)
            .font(.system(size: 11))
            .padding(.leading, 4)
        }
    }
}

private struct KeyLegend: View {
    private let keys: [(symbol: String, name: String)] = [
        ("⌘", "Command"),
        ("⌥", "Option"),
        ("⌃", "Control"),
        ("⇧", "Shift"),
        ("⌫", "Delete"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                ForEach(keys, id: \.symbol) { key in
                    HStack(spacing: 4) {
                        KeyCap(key.symbol, compact: true)
                        Text(key.name)
                            .font(.system(size: 10.5))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Text("Windows keyboard plugged in? The Win key is ⌘ and Alt is ⌥.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .card()
    }
}

private struct GroupSection: View {
    let group: ShortcutGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(group.title, systemImage: group.symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                ForEach(Array(group.shortcuts.enumerated()), id: \.element.id) { index, shortcut in
                    if index > 0 {
                        Divider()
                            .padding(.leading, 12)
                    }
                    ShortcutRow(shortcut: shortcut)
                }
            }
            .card()
        }
    }
}

private struct ShortcutRow: View {
    let shortcut: Shortcut

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(shortcut.action)
                    .font(.system(size: 12.5, weight: .medium))
                Text("Windows: \(shortcut.windows)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                if let note = shortcut.note {
                    Text(note)
                        .font(.system(size: 10.5))
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                ForEach(Array(shortcut.mac.enumerated()), id: \.offset) { index, keys in
                    if index > 0 {
                        Text(shortcut.joiner)
                            .font(.system(size: 10.5))
                            .foregroundStyle(.tertiary)
                    }
                    KeyCap(keys)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }
}
