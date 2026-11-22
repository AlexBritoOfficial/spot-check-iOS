import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// Fixed dark palette pulled directly from the design canvas's 19
/// screens (not derived/approximated) -- every one of them is dark, with
/// no light-mode variant anywhere, so this is intentionally NOT an
/// adaptive color set. Info.plist forces UIUserInterfaceStyle = Dark to
/// match.
enum SCColor {
    /// Base app background (most screens' body).
    static let background = Color(hex: 0x15181F)
    /// Darker background used by the splash screen and the map canvas.
    static let backgroundDeep = Color(hex: 0x0A0D12)
    /// Elevated surface: cards, list rows, input fields.
    static let surface = Color(hex: 0x20242C)
    /// The darker of the two bands in the canvas's diagonal "media not
    /// loaded yet" hatch (clip thumbnails, spot photos).
    static let surfaceAlt = Color(hex: 0x1A1E25)
    /// Borders, dividers, unselected chip/button outlines. Also doubles
    /// as the fill for input fields (Login/Signup/AddSpot/Booking all
    /// use this exact hex for `background` on inputs, not just borders).
    static let border = Color(hex: 0x2D333D)
    static let inputFill = border

    static let textPrimary = Color.white
    /// Body copy that isn't the primary heading/label color.
    static let textBody = Color(hex: 0xC5CAD3)
    /// Muted labels, placeholders, timestamps, helper text.
    static let textSecondary = Color(hex: 0x979FAB)

    /// Brand gold -- primary CTAs, the "CHECK" wordmark, active filter
    /// chips, the selected map pin.
    static let accent = Color(hex: 0xE6AD00)
    static let accentHover = Color(hex: 0xFFC61A)

    /// Difficulty scale (also reused for status indicators where the
    /// semantics line up: confirmed/passed = success, pro/danger = red).
    static let difficultyBeginner = Color(hex: 0x4AC06C)
    static let difficultyIntermediate = Color(hex: 0xD4AF37)
    static let difficultyAdvanced = Color(hex: 0xFFA500)
    static let difficultyPro = Color(hex: 0xF0806A)

    static let success = difficultyBeginner
    static let danger = difficultyPro
    /// Geolocation "you are here" marker.
    static let info = Color(hex: 0x5B8DEF)
    /// Default (non-owned) map pin fill.
    static let pinDefault = Color(hex: 0xE8E8E8)

    static func color(for difficulty: Difficulty) -> Color {
        switch difficulty {
        case .beginner: difficultyBeginner
        case .intermediate: difficultyIntermediate
        case .advanced: difficultyAdvanced
        case .pro: difficultyPro
        }
    }
}
