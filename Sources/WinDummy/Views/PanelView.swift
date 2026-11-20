import SwiftUI

/// The whole floating panel: header, quick actions, then the two tabs.
struct PanelView: View {
    @EnvironmentObject private var model: PanelModel

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()
            ActionRow()

            Picker("View", selection: $model.tab) {
                ForEach(PanelModel.Tab.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, Theme.sidePadding)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Group {
                switch model.tab {
                case .clipboard:
                    ClipboardView()
                case .characters:
                    CharactersView()
                case .cheatSheet:
                    CheatSheetView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            FooterView()
        }
        .frame(width: Theme.panelSize.width, height: Theme.panelSize.height)
        .background(VisualEffectBackground())
        .ignoresSafeArea()
        .onExitCommand {
            model.onClose()
        }
    }
}

// MARK: - Header

private struct HeaderView: View {
    @EnvironmentObject private var model: PanelModel

    var body: some View {
        HStack(spacing: 10) {
            AppBadge()

            VStack(alignment: .leading, spacing: 1) {
                Text("WinDummy")
                    .font(.system(size: 14, weight: .semibold))
                Text("For lost Windows people on Mac")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Menu {
                Toggle(
                    "Launch at login",
                    isOn: Binding(
                        get: { model.launchAtLogin },
                        set: { model.setLaunchAtLogin($0) }
                    )
                )
                if !model.canDirectPaste {
                    Button("Enable direct paste…") {
                        model.onEnableDirectPaste()
                    }
                }
                Button("Clear clipboard history") {
                    model.onClearHistory()
                }
                Divider()
                Button("Quit WinDummy") {
                    model.onQuit()
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("Options")
        }
        .padding(.horizontal, Theme.sidePadding)
        // The top 28 points are the (invisible) title bar, which swallows clicks.
        // The padding keeps the ⋯ button clear of it.
        .padding(.top, 22)
        .padding(.bottom, 14)
    }
}

// MARK: - Quick actions

private struct ActionRow: View {
    @EnvironmentObject private var model: PanelModel

    var body: some View {
        HStack(spacing: 10) {
            ActionTile(
                symbol: "scissors",
                title: "Snip area",
                keys: "⌃⌥⌘S",
                windowsKeys: "Win+Shift+S",
                tint: .blue
            ) {
                model.onSnipArea()
            }
            ActionTile(
                symbol: "macwindow",
                title: "Copy window",
                keys: "⌃⌥⌘W",
                windowsKeys: "Alt+PrtScn",
                tint: .purple
            ) {
                model.onSnipWindow()
            }
            ActionTile(
                symbol: "record.circle",
                title: "Record & more",
                keys: "⇧⌘5",
                windowsKeys: "Win+Shift+R",
                tint: .pink
            ) {
                model.onOpenScreenshotToolbar()
            }
        }
        .padding(.horizontal, Theme.sidePadding)
    }
}

private struct ActionTile: View {
    let symbol: String
    let title: String
    let keys: String
    let windowsKeys: String
    let tint: Color
    let action: () -> Void

    @EnvironmentObject private var hover: HoverTracker

    private var hoverID: String { "tile-" + title }
    private var isHovered: Bool { hover.hoveredID == hoverID }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 9) {
                Image(systemName: symbol)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(tint.opacity(0.16))
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 12.5, weight: .semibold))
                        .lineLimit(1)
                    Text(keys)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.primary.opacity(isHovered ? 0.11 : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovering in
            hover.update(hoverID, isHovering: isHovering)
        }
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .help("On Windows: \(windowsKeys)")
    }
}

// MARK: - Footer

private struct FooterView: View {
    @EnvironmentObject private var model: PanelModel

    var body: some View {
        HStack(spacing: 6) {
            KeyCap("⌃⌥⌘V", compact: true)
            Text("opens this anywhere")

            Spacer()

            if model.canDirectPaste {
                Label("Direct paste on", systemImage: "checkmark.circle.fill")
            } else {
                Button("Enable direct paste") {
                    model.onEnableDirectPaste()
                }
                .buttonStyle(.link)
                .help("Lets a picked clip paste straight away, like Win+V. Needs the Accessibility permission.")
            }
        }
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
        .padding(.horizontal, Theme.sidePadding)
        .padding(.vertical, 10)
        .background(Color.primary.opacity(0.04))
        .overlay(alignment: .top) {
            Divider()
        }
    }
}
