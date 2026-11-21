import CoreGraphics

/// Spacing/radius constants pulled from the design canvas's inline
/// styles (buttons/inputs are consistently 52px tall, cards 14-16px
/// radius, sheets/capsules 20-22px, badges 6px).
enum SCRadius {
    static let badge: CGFloat = 6
    static let control: CGFloat = 12
    static let card: CGFloat = 16
    static let sheet: CGFloat = 22
    static let capsule: CGFloat = 999
}

enum SCMetric {
    static let controlHeight: CGFloat = 52
    static let chipHeight: CGFloat = 36
    static let screenPadding: CGFloat = 20
    static let cardPadding: CGFloat = 14
}
