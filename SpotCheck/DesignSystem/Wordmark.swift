import SwiftUI

/// The "SPOT CHECK" wordmark + pin glyph used on Login/Signup/Menu/the
/// splash screen.
struct Wordmark: View {
    var size: CGFloat = 20

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: size * 1.1))
                .foregroundStyle(SCColor.background, SCColor.accent)
            HStack(spacing: 6) {
                Text("SPOT").foregroundStyle(SCColor.textPrimary)
                Text("CHECK").foregroundStyle(SCColor.accent)
            }
            .font(SCFont.headingFixed(size))
        }
    }
}

#Preview {
    Wordmark()
        .padding()
        .background(SCColor.background)
}
