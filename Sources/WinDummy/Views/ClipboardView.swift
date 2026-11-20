import AppKit
import SwiftUI

/// Clipboard history: type to filter, ↑↓ to choose, Return or a click to paste.
struct ClipboardView: View {
    @EnvironmentObject private var model: PanelModel
    @EnvironmentObject private var clipboard: ClipboardStore
    @FocusState private var searchFocused: Bool

    private var query: String {
        model.query.trimmingCharacters(in: .whitespaces)
    }

    private func filter(_ items: [ClipItem]) -> [ClipItem] {
        guard !query.isEmpty else { return items }
        return items.filter { $0.searchableText.localizedCaseInsensitiveContains(query) }
    }

    private var filteredPinned: [ClipItem] { filter(clipboard.pinned) }
    private var filteredHistory: [ClipItem] { filter(clipboard.items) }
    /// Everything shown, top to bottom. Indexes into this drive ⌘1–⌘9 and the selection.
    private var shown: [ClipItem] { filteredPinned + filteredHistory }

    private var isEmpty: Bool {
        clipboard.items.isEmpty && clipboard.pinned.isEmpty
    }

    private var optionHeld: Bool {
        NSEvent.modifierFlags.contains(.option)
    }

    var body: some View {
        VStack(spacing: 8) {
            SearchField(text: $model.query, prompt: "Search clipboard history", focused: $searchFocused)
                .onSubmit {
                    let shown = shown
                    if shown.indices.contains(model.selectedIndex) {
                        model.onPick(shown[model.selectedIndex], optionHeld)
                    } else if let first = shown.first {
                        model.onPick(first, optionHeld)
                    }
                }
                .onKeyPress(.downArrow) {
                    model.selectedIndex = min(model.selectedIndex + 1, max(shown.count - 1, 0))
                    return .handled
                }
                .onKeyPress(.upArrow) {
                    model.selectedIndex = max(model.selectedIndex - 1, 0)
                    return .handled
                }

            if !isEmpty {
                Text("↑↓ to choose, Return to paste. Hold ⌥ to paste as plain text.")
                    .font(.system(size: 10.5))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Theme.sidePadding + 4)
            }

            if isEmpty {
                EmptyState(
                    symbol: "doc.on.clipboard",
                    title: "Nothing copied yet",
                    message: "Copy something with ⌘C and it shows up here.\nHistory stays in memory and is gone when you quit."
                )
            } else if shown.isEmpty {
                EmptyState(
                    symbol: "magnifyingglass",
                    title: "No matches",
                    message: "Nothing in the history contains that text."
                )
            } else {
                list
            }
        }
        .onAppear {
            searchFocused = true
        }
        .onChange(of: model.openCount) { _, _ in
            searchFocused = true
        }
        .onChange(of: model.query) { _, _ in
            model.selectedIndex = 0
        }
    }

    private var list: some View {
        let pinnedCount = filteredPinned.count
        return ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    if pinnedCount > 0 {
                        SectionTitle(title: "Pinned", symbol: "pin.fill")
                    }
                    ForEach(Array(shown.enumerated()), id: \.element.id) { index, item in
                        if index == pinnedCount, pinnedCount > 0 {
                            SectionTitle(title: "History", symbol: "clock")
                                .padding(.top, 6)
                        }
                        ClipRow(
                            item: item,
                            index: index,
                            isSelected: index == model.selectedIndex,
                            isPinned: index < pinnedCount,
                            onPin: {
                                withAnimation(.easeOut(duration: 0.15)) {
                                    clipboard.togglePin(item)
                                }
                            },
                            onDelete: {
                                withAnimation(.easeOut(duration: 0.15)) {
                                    clipboard.remove(item)
                                }
                            },
                            action: {
                                model.onPick(item, optionHeld)
                            }
                        )
                        .id(item.id)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
            }
            .onChange(of: model.selectedIndex) { _, index in
                let shown = shown
                guard shown.indices.contains(index) else { return }
                proxy.scrollTo(shown[index].id)
            }
        }
    }
}

private struct SectionTitle: View {
    let title: String
    let symbol: String

    var body: some View {
        Label(title, systemImage: symbol)
            .font(.system(size: 10.5, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.leading, 10)
            .padding(.vertical, 2)
    }
}

private struct ClipRow: View {
    let item: ClipItem
    let index: Int
    let isSelected: Bool
    let isPinned: Bool
    let onPin: () -> Void
    let onDelete: () -> Void
    let action: () -> Void

    @EnvironmentObject private var hover: HoverTracker

    private var hoverID: String { "clip-" + item.id.uuidString }
    private var isHovered: Bool { hover.hoveredID == hoverID }

    private var background: Color {
        if isSelected { return Color.accentColor.opacity(0.18) }
        if isHovered { return Color.primary.opacity(0.09) }
        return .clear
    }

    /// Long texts are cut to two lines in the row; hovering shows more.
    private var tooltip: String {
        switch item.content {
        case .text(let string):
            return string.count > 1500 ? String(string.prefix(1500)) + "…" : string
        case .files(let urls, _):
            return urls.map(\.path).joined(separator: "\n")
        case .image:
            return ""
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 10) {
                preview
                Spacer(minLength: 6)
                VStack(alignment: .trailing, spacing: 4) {
                    if index < 9 {
                        KeyCap("⌘\(index + 1)", compact: true)
                    }
                    Text(item.date.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(background)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .modifier(QuickPickShortcut(index: index))
        .help(tooltip)
        // Pin and delete sit on top of the row, just left of the ⌘-number,
        // and only while the pointer is over the row.
        .overlay(alignment: .trailing) {
            if isHovered {
                HStack(spacing: 0) {
                    RowButton(symbol: isPinned ? "pin.slash.fill" : "pin.fill",
                              help: isPinned ? "Unpin" : "Pin: keep it, also after a restart",
                              action: onPin)
                    RowButton(symbol: "xmark.circle.fill", help: "Remove", action: onDelete)
                }
                .padding(.trailing, 50)
            }
        }
        .contextMenu {
            Button(isPinned ? "Unpin" : "Pin", action: onPin)
            Button("Remove", action: onDelete)
        }
        .onHover { isHovering in
            hover.update(hoverID, isHovering: isHovering)
        }
    }

    @ViewBuilder
    private var preview: some View {
        switch item.content {
        case .text(let string):
            VStack(alignment: .leading, spacing: 3) {
                Text(string.trimmingCharacters(in: .whitespacesAndNewlines))
                    .font(.system(size: 12.5))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let appName = item.appName {
                    Text(appName)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }
        case .files(let urls, let icon):
            HStack(spacing: 10) {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 32, height: 32)
                VStack(alignment: .leading, spacing: 3) {
                    Text(urls.count == 1 ? urls[0].lastPathComponent : "\(urls.count) files")
                        .font(.system(size: 12.5))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text(urls.count == 1 ? urls[0].deletingLastPathComponent().path : urls.map(\.lastPathComponent).joined(separator: ", "))
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer(minLength: 0)
            }
        case .image(let image, let pixelSize):
            HStack(spacing: 10) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 110, maxHeight: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                    )
                VStack(alignment: .leading, spacing: 3) {
                    Text("Image")
                        .font(.system(size: 12.5))
                    Text(verbatim: "\(Int(pixelSize.width)) × \(Int(pixelSize.height))")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

private struct RowButton: View {
    let symbol: String
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .padding(4)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
    }
}

/// ⌘1 to ⌘9 pick the first nine entries.
private struct QuickPickShortcut: ViewModifier {
    let index: Int

    func body(content: Content) -> some View {
        if index < 9 {
            content.keyboardShortcut(KeyEquivalent(Character(String(index + 1))), modifiers: .command)
        } else {
            content
        }
    }
}
