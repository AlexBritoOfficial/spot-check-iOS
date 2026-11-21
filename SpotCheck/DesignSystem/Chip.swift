import SwiftUI

/// The pill-shaped toggle used for the Map's filter row and AddSpot's
/// spot-type/feature pickers. Active = filled gold; inactive = outlined.
struct Chip: View {
    let label: String
    let isActive: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label.uppercased())
                .font(SCFont.badgeLabel)
                .foregroundStyle(isActive ? SCColor.background : SCColor.textPrimary)
                .padding(.horizontal, 14)
                .frame(height: 36)
                .background(isActive ? SCColor.accent : SCColor.background)
                .overlay(
                    Capsule().stroke(isActive ? SCColor.accent : SCColor.border, lineWidth: 1.5)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack {
        Chip(label: "Park", isActive: true) {}
        Chip(label: "Street", isActive: false) {}
        Chip(label: "DIY", isActive: false) {}
    }
    .padding()
    .background(SCColor.background)
}
