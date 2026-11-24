import Foundation

/// Spot Check's two fee models, which differ by flow and by who bears the
/// fee. They are not one rate, and the canvas is deliberate about it:
///
/// - **Filming** adds `filmingSessionPercent` on top of the filmer's rate,
///   so the *skater* pays it and `Payouts` can promise the filmer "You keep
///   100% of your rate".
/// - **Pro requests** take `proRequestPercent` out of the price, so the
///   *pro* bears it -- `Trust/ProReplyScreen` breaks out "Skater paid /
///   Spot Check fee / You earn" and `Payouts` says "Price minus 20% fee".
///
/// These constants are for display copy only. The fee actually charged
/// belongs to each payment row, so a rate change never rewrites history.
enum PaymentFees {
    static let filmingSessionPercent = 15
    static let proRequestPercent = 20

    /// The canvas's "Spot Check fee (15%)" / "(20%)" label.
    static func label(percent: Int) -> String {
        "Spot Check fee (\(percent)%)"
    }
}
