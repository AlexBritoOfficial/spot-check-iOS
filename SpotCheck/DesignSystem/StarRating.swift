import SwiftUI

/// Read-only 5-star display (SpotDetail). There's no rating *input* UI
/// anywhere in the design canvas, matching the web app -- new spots are
/// always created with rating 0.
struct StarRating: View {
    let rating: Int
    var maxRating: Int = 5

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<maxRating, id: \.self) { index in
                Image(systemName: index < rating ? "star.fill" : "star")
                    .foregroundStyle(SCColor.accent)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Rated \(rating) out of \(maxRating)")
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        StarRating(rating: 5)
        StarRating(rating: 3)
        StarRating(rating: 0)
    }
    .padding()
    .background(SCColor.background)
}
