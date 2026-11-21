import SwiftUI

/// Two-color scheme: default vs. owned-by-me (the design canvas's own
/// color-coding convention, "gold = selected," is folded in as a ring
/// rather than overriding the ownership color -- a third color for
/// "owned by someone else" is deliberately deferred, matching the web
/// app's documented decision).
struct SpotPin: View {
    let isOwnedByMe: Bool
    let isSelected: Bool

    private var fillColor: Color {
        isOwnedByMe ? SCColor.accent : SCColor.pinDefault
    }

    var body: some View {
        ZStack {
            if isSelected {
                Circle()
                    .stroke(SCColor.accent, lineWidth: 3)
                    .frame(width: 38, height: 38)
            }
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: isSelected ? 30 : 22))
                .foregroundStyle(SCColor.background, fillColor)
                .shadow(radius: 2)
        }
    }
}

#Preview {
    HStack(spacing: 24) {
        SpotPin(isOwnedByMe: false, isSelected: false)
        SpotPin(isOwnedByMe: true, isSelected: false)
        SpotPin(isOwnedByMe: false, isSelected: true)
        SpotPin(isOwnedByMe: true, isSelected: true)
    }
    .padding()
    .background(SCColor.backgroundDeep)
}
