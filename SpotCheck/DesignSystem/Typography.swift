import SwiftUI

/// Archivo Black is the design canvas's display face -- used for the
/// wordmark, screen titles, buttons, badges and section labels
/// throughout all 19 screens. Body copy stays the system font (the
/// canvas uses `system-ui`), so there's no custom body font here.
enum SCFont {
    private static let name = "ArchivoBlack-Regular"

    static func heading(_ size: CGFloat) -> Font {
        .custom(name, size: size, relativeTo: .largeTitle)
    }

    /// Fixed-size variant for places that shouldn't scale with Dynamic
    /// Type (the wordmark, pill/badge labels, tab bar labels) -- matches
    /// how the canvas treats them as chrome, not reading content.
    static func headingFixed(_ size: CGFloat) -> Font {
        .custom(name, fixedSize: size)
    }

    // Semantic presets, matching sizes actually used across the canvas.
    static let screenTitle = heading(28)
    static let sectionLabel = headingFixed(12)
    static let buttonLabel = headingFixed(15)
    static let badgeLabel = headingFixed(11)
    static let tabLabel = headingFixed(10.5)
}
