import SwiftUI

/// The canvas's floating peek card for the selected pin: an 84pt
/// thumbnail, the spot's tags, and a chevron into `SpotDetailScreen`.
struct SpotPeekCard: View {
    let spot: Spot
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                SCMediaPlaceholder()
                    .frame(width: 84, height: 84)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(spot.name)
                            .font(SCFont.headingFixed(18))
                            .foregroundStyle(SCColor.textPrimary)
                        Spacer()
                        if let distance = spot.distanceMeters {
                            Text(formattedDistance(distance))
                                .font(.system(size: 13))
                                .foregroundStyle(SCColor.textSecondary)
                        }
                    }

                    HStack(spacing: 6) {
                        Badge(text: spot.spotType.rawValue)
                        Badge.difficulty(spot.difficulty)
                    }

                    if let description = spot.description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 13))
                            .foregroundStyle(SCColor.textSecondary)
                            .lineLimit(1)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(SCColor.textSecondary)
            }
            .padding(12)
            .frame(height: 108)
            .scCard(cornerRadius: 18, fill: SCColor.background)
            .shadow(color: .black.opacity(0.5), radius: 16, y: 12)
        }
        .buttonStyle(.plain)
    }

    private func formattedDistance(_ meters: Double) -> String {
        String(format: "%.1f mi", meters / 1609.34)
    }
}
