import SwiftUI

/// Matches the small outlined label used throughout the canvas for spot
/// type, difficulty, and status tags (e.g. SpotDetail, Bookmarks, the
/// Map peek card).
struct Badge: View {
    let text: String
    var color: Color = SCColor.textSecondary

    var body: some View {
        Text(text.uppercased())
            .font(SCFont.badgeLabel)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(SCColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(SCColor.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    static func difficulty(_ difficulty: Difficulty) -> Badge {
        Badge(text: difficulty.rawValue, color: SCColor.color(for: difficulty))
    }
}

#Preview {
    VStack(spacing: 12) {
        HStack {
            Badge(text: "Street")
            Badge.difficulty(.beginner)
            Badge.difficulty(.intermediate)
            Badge.difficulty(.advanced)
            Badge.difficulty(.pro)
        }
    }
    .padding()
    .background(SCColor.background)
}
