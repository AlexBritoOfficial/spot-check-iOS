import CoreGraphics

/// Spacing/radius constants pulled from the design canvas's inline
/// styles (buttons/inputs are consistently 52px tall, cards 14-16px
/// radius, sheets/capsules 20-22px, badges 6px).
enum SCRadius {
    static let badge: CGFloat = 6
    static let control: CGFloat = 12
    /// Trays and inset rows (the canvas's 14px radius).
    static let cardSmall: CGFloat = 14
    static let card: CGFloat = 16
    static let sheet: CGFloat = 22
    static let capsule: CGFloat = 999
}

enum SCMetric {
    static let controlHeight: CGFloat = 52
    static let chipHeight: CGFloat = 36
    static let screenPadding: CGFloat = 20
    static let cardPadding: CGFloat = 14

    /// Height of the custom bottom nav's own content (the canvas's 88px
    /// bar minus its 26px home-indicator padding, which SwiftUI's safe
    /// area supplies instead).
    static let bottomNavHeight: CGFloat = 62
    /// Bottom padding a nav-bar screen's scrolling content needs so its
    /// last row clears the bar (the canvas uses 110px).
    static let bottomNavClearance: CGFloat = 96

    /// The canvas measures from the top of a 390x844 artboard, status
    /// bar included; SwiftUI already insets by the status bar, so a
    /// canvas y-offset has to have it subtracted back out.
    private static let canvasStatusBar: CGFloat = 46

    static func headerTop(_ canvasOffset: CGFloat) -> CGFloat {
        max(0, canvasOffset - canvasStatusBar)
    }
}
