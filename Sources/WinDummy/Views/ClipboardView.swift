import AppKit
import SwiftUI

/// Clipboard history: type to filter, click or press Return to paste.
struct ClipboardView: View {
    @EnvironmentObject private var model: PanelModel
    @EnvironmentObject private var clipboard: ClipboardStore
    @FocusState private var searchFocused: Bool

    private var filteredItems: [ClipItem] {
        let query = model.query.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return clipboard.items }
        return clipboard.items.filter { item in
            item.searchableText.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            SearchField(text: $model.query, prompt: "Search clipboard history", focused: $searchFocused)
                .onSubmit {
                    if let first = filteredItems.first {
                        model.onPick(first)
                    }
                }

            if clipboard.items.isEmpty {
                EmptyState(
                    symbol: "doc.on.clipboard",
                    title: "Nothing copied yet",
                    message: "Copy something with ⌘C and it shows up here.\nHistory stays in memory and is gone when you quit."
                )
            } else if filteredItems.isEmpty {
                EmptyState(
                    symbol: "magnifyingglass",
                    title: "No matches",
                    message: "Nothing in the history contains that text."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                            ClipRow(item: item, index: index) {
                                model.onPick(item)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 8)
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

private struct ClipRow: View {
    let item: ClipItem
    let index: Int
    let action: () -> Void

    @EnvironmentObject private var hover: HoverTracker

    private var hoverID: String { "clip-" + item.id.uuidString }
    private var isHovered: Bool { hover.hoveredID == hoverID }

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
                    .fill(Color.primary.opacity(isHovered ? 0.09 : 0))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering in
            hover.update(hoverID, isHovering: isHovering)
        }
        .modifier(QuickPickShortcut(index: index))
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
        case .image(let image):
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
                    Text(verbatim: "\(Int(image.size.width)) × \(Int(image.size.height))")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
                Spacer(minLength: 0)
            }
        }
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
