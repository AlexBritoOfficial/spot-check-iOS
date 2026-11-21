import SwiftUI

/// Floating card shown when a pin is selected -- tapping it opens
/// SpotDetailScreen. Mirrors the web app's "selected spot peek" card.
struct SpotPeekCard: View {
    let spot: Spot
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: SCRadius.control)
                    .fill(SCColor.border)
                    .frame(width: 72, height: 72)
                    .overlay(Image(systemName: "photo").foregroundStyle(SCColor.textSecondary))

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(spot.name)
                            .font(SCFont.headingFixed(17))
                            .foregroundStyle(SCColor.textPrimary)
                        Spacer()
                        if let distance = spot.distanceMeters {
                            Text(formattedDistance(distance))
                                .font(.caption)
                                .foregroundStyle(SCColor.textSecondary)
                        }
                    }
                    HStack(spacing: 6) {
                        Badge(text: spot.spotType.rawValue)
                        Badge.difficulty(spot.difficulty)
                    }
                    if let description = spot.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(SCColor.textSecondary)
                            .lineLimit(1)
                    }
                }

                Image(systemName: "chevron.right")
                    .foregroundStyle(SCColor.textSecondary)
            }
            .padding(12)
            .background(SCColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: SCRadius.sheet - 4))
            .shadow(color: .black.opacity(0.4), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }

    private func formattedDistance(_ meters: Double) -> String {
        String(format: "%.1f mi", meters / 1609.34)
    }
}
