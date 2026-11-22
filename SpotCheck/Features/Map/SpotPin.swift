import SwiftUI

/// Two-color scheme: default vs. owned-by-me (the design canvas's own
/// color-coding convention, "gold = selected," is folded in as the
/// selected pin's larger size and dark centre -- a third color for
/// "owned by someone else" is deliberately deferred, matching the web
/// app's documented decision).
struct SpotPin: View {
    let isOwnedByMe: Bool
    let isSelected: Bool

    private var fillColor: Color {
        isOwnedByMe || isSelected ? SCColor.accent : SCColor.pinDefault
    }

    var body: some View {
        SCPinGlyph(
            height: isSelected ? 55 : 39,
            fill: fillColor,
            showsHole: isSelected || isOwnedByMe,
            strokeColor: SCColor.background
        )
        .shadow(color: .black.opacity(0.35), radius: 3, y: 2)
    }
}

#Preview {
    HStack(alignment: .bottom, spacing: 24) {
        SpotPin(isOwnedByMe: false, isSelected: false)
        SpotPin(isOwnedByMe: true, isSelected: false)
        SpotPin(isOwnedByMe: false, isSelected: true)
        SpotPin(isOwnedByMe: true, isSelected: true)
    }
    .padding()
    .background(SCColor.backgroundDeep)
}
