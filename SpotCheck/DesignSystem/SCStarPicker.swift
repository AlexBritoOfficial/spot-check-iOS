import SwiftUI

/// Tappable counterpart to `StarRating` (which is display only): the
/// 48pt star buttons the canvas uses on BustLog and the two-way session
/// rating.
struct SCStarPicker: View {
    @Binding var rating: Int
    var starSize: CGFloat = 32
    var spacing: CGFloat = 4
    var accessibilityTitle: String = "Rating"

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(1...5, id: \.self) { value in
                Button {
                    rating = value
                } label: {
                    Image(systemName: "star.fill")
                        .font(.system(size: starSize))
                        .foregroundStyle(value <= rating ? SCColor.accent : SCColor.border)
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(value == 1 ? "1 star" : "\(value) stars")
                .accessibilityAddTraits(value <= rating ? [.isSelected, .isButton] : .isButton)
            }
        }
        .accessibilityLabel(accessibilityTitle)
    }
}

#Preview {
    @Previewable @State var rating = 4

    return SCStarPicker(rating: $rating)
        .padding()
        .background(SCColor.background)
}
