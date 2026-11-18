import AppKit
import SwiftUI

/// Shared sizes and colours.
enum Theme {
    static let panelSize = CGSize(width: 420, height: 600)
    static let cornerRadius: CGFloat = 12
    static let sidePadding: CGFloat = 16

    static let brandBlue = Color(red: 0.20, green: 0.48, blue: 1.00)
    static let brandPurple = Color(red: 0.56, green: 0.34, blue: 0.98)
    static let brandGradient = LinearGradient(
        colors: [brandBlue, brandPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

/// Frosted glass that blurs whatever is behind the window. Follows light and dark mode.
struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .popover
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

/// A keyboard key, or a key combination, drawn as a little keycap.
struct KeyCap: View {
    private let text: String
    private let compact: Bool

    init(_ text: String, compact: Bool = false) {
        self.text = text
        self.compact = compact
    }

    var body: some View {
        Text(text)
            .font(.system(size: compact ? 10.5 : 12, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.primary.opacity(0.85))
            .padding(.horizontal, compact ? 5 : 7)
            .padding(.vertical, compact ? 2 : 3)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.primary.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
            )
            .fixedSize()
    }
}

/// The app's mark: a ⌘ on the brand gradient.
struct AppBadge: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(Theme.brandGradient)
            .frame(width: 34, height: 34)
            .overlay(
                Image(systemName: "command")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.white)
            )
            .shadow(color: Color.black.opacity(0.18), radius: 3, x: 0, y: 1)
    }
}

struct SearchField: View {
    @Binding var text: String
    let prompt: String
    var focused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField(prompt, text: $text)
                .textFieldStyle(.plain)
                .focused(focused)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .help("Clear search")
            }
        }
        .font(.system(size: 13))
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.primary.opacity(0.06))
        )
        .padding(.horizontal, Theme.sidePadding)
    }
}

struct EmptyState: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension View {
    /// The subtle rounded card used behind grouped rows.
    func card() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .fill(Color.primary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }
}
