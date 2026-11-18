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

    var body: some View {
        VStack(spacing: 8) {
            SearchField(text: $model.cheatSheetQuery, prompt: "Search, for example “rename” or “Alt+Tab”", focused: $searchFocused)

            if filteredGroups.isEmpty {
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
