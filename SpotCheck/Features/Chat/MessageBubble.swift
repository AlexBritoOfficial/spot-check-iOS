import SwiftUI

/// Canvas bubble shapes: both are 18pt-rounded with a 6pt notch on the
/// sender's side, mine filled gold with dark text, theirs the bordered
/// surface. A shared spot replaces the bubble with the canvas's 250pt
/// card.
struct MessageBubble: View {
    let message: Message
    let isMine: Bool
    let sharedSpot: Spot?
    var onTapSharedSpot: ((Spot) -> Void)?

    var body: some View {
        HStack {
            if isMine { Spacer(minLength: 40) }

            Group {
                if let sharedSpot {
                    sharedSpotCard(sharedSpot)
                } else if let body = message.body {
                    Text(body)
                        .font(.system(size: 15, weight: isMine ? .medium : .regular))
                        .lineSpacing(3)
                        .foregroundStyle(isMine ? SCColor.background : SCColor.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(maxWidth: 270, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .background(isMine ? SCColor.accent : SCColor.surface)
                        .overlay(
                            bubbleShape
                                .stroke(isMine ? .clear : SCColor.border, lineWidth: 1)
                        )
                        .clipShape(bubbleShape)
                } else {
                    Text("Shared a spot")
                        .font(.system(size: 12.5))
                        .foregroundStyle(SCColor.textSecondary)
                }
            }

            if !isMine { Spacer(minLength: 40) }
        }
    }

    private var bubbleShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            cornerRadii: .init(
                topLeading: 18,
                bottomLeading: isMine ? 18 : 6,
                bottomTrailing: isMine ? 6 : 18,
                topTrailing: 18
            )
        )
    }

    private func sharedSpotCard(_ spot: Spot) -> some View {
        Button {
            onTapSharedSpot?(spot)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                SCMediaPlaceholder(cornerRadius: 0)
                    .frame(height: 96)
                    .overlay(alignment: .topLeading) {
                        SCPinGlyph(height: 34, showsHole: true, strokeColor: SCColor.background)
                            .padding(12)
                    }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(spot.name)
                            .font(SCFont.headingFixed(15))
                            .foregroundStyle(SCColor.textPrimary)
                        Spacer()
                        if let distance = spot.distanceMeters {
                            Text(String(format: "%.1f mi", distance / 1609.34))
                                .font(.system(size: 12))
                                .foregroundStyle(SCColor.textSecondary)
                        }
                    }

                    HStack(spacing: 6) {
                        Badge(text: spot.spotType.rawValue)
                        Badge.difficulty(spot.difficulty)
                    }

                    Text("View spot")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(SCColor.accent)
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 12)
            }
            .frame(width: 250)
            .background(SCColor.background)
            .overlay(bubbleShape.stroke(SCColor.border, lineWidth: 1))
            .clipShape(bubbleShape)
        }
        .buttonStyle(.plain)
    }
}
