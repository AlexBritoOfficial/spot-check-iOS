import SwiftUI

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
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(isMine ? Color.accentColor : Color(.secondarySystemBackground))
                        .foregroundStyle(isMine ? Color.white : Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                } else {
                    Text("Shared a spot")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !isMine { Spacer(minLength: 40) }
        }
    }

    private func sharedSpotCard(_ spot: Spot) -> some View {
        Button {
            onTapSharedSpot?(spot)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: 180, height: 90)
                    .overlay(Image(systemName: "mappin.circle.fill").foregroundStyle(.secondary))
                Text(spot.name).font(.subheadline.bold()).foregroundStyle(.primary)
                Text("\(spot.spotType.rawValue.capitalized) · \(spot.difficulty.rawValue.capitalized)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .frame(width: 200, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
