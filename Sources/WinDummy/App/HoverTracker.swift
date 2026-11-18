import SwiftUI

/// Remembers which row or tile the pointer is over, so it can be highlighted.
///
/// Why not `@State` in each view? In recent SDKs `@State` is a macro, and its
/// compiler plugin ships only with full Xcode. Keeping view state in observable
/// objects lets the project build with just the Command Line Tools.
final class HoverTracker: ObservableObject {
    @Published private(set) var hoveredID: String?

    func update(_ id: String, isHovering: Bool) {
        if isHovering {
            hoveredID = id
        } else if hoveredID == id {
            hoveredID = nil
        }
    }

    func clear() {
        hoveredID = nil
    }
}
