import SwiftUI

/// Circular initial-letter avatar, matching the canvas's Menu/Messages/
/// SkaterProfile/Chat usage: a plain gold circle in the Menu drawer, a
/// ringed + "skating now" dot variant on profiles and the Messages rail.
struct Avatar: View {
    let initial: String
    var size: CGFloat = 56
    var ringColor: Color?
    var backgroundColor: Color = SCColor.accent
    var foregroundColor: Color = SCColor.background
    var isOnline: Bool = false

    private var ringPadding: CGFloat { ringColor != nil ? max(3, size * 0.04) : 0 }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(backgroundColor)
                .frame(width: size, height: size)
                .overlay(
                    Text(initial.uppercased().prefix(1))
                        .font(SCFont.headingFixed(size * 0.36))
                        .foregroundStyle(foregroundColor)
                )
                .padding(ringPadding)
                .overlay(
                    Circle().stroke(ringColor ?? .clear, lineWidth: ringColor != nil ? 3 : 0)
                )

            if isOnline {
                Circle()
                    .fill(SCColor.success)
                    .frame(width: max(12, size * 0.22), height: max(12, size * 0.22))
                    .overlay(Circle().stroke(SCColor.background, lineWidth: 3))
            }
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        Avatar(initial: "R", size: 56)
        Avatar(initial: "S", size: 80, ringColor: SCColor.accent, backgroundColor: SCColor.surface, foregroundColor: .white, isOnline: true)
        Avatar(initial: "O", size: 44, backgroundColor: SCColor.surface, foregroundColor: .white)
    }
    .padding()
    .background(SCColor.background)
}
