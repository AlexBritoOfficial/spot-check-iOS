import SwiftUI

/// Filled gold CTA: 52px tall, 12px radius, `#15181f` label. The
/// canvas's primary action on every screen that has one.
struct SCPrimaryButtonStyle: ButtonStyle {
    var fontSize: CGFloat = 15
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SCFont.headingFixed(fontSize))
            .foregroundStyle(SCColor.background)
            .frame(maxWidth: .infinity)
            .frame(height: SCMetric.controlHeight)
            .background(SCColor.accent.opacity(isEnabled ? 1 : 0.4))
            .clipShape(RoundedRectangle(cornerRadius: SCRadius.control))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

/// Outlined companion to the gold CTA: 1.5px `#2d333d` border over the
/// screen background, white label.
struct SCSecondaryButtonStyle: ButtonStyle {
    var fontSize: CGFloat = 15

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SCFont.headingFixed(fontSize))
            .foregroundStyle(SCColor.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: SCMetric.controlHeight)
            .overlay(
                RoundedRectangle(cornerRadius: SCRadius.control)
                    .stroke(SCColor.border, lineWidth: 1.5)
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension ButtonStyle where Self == SCPrimaryButtonStyle {
    static var scPrimary: SCPrimaryButtonStyle { SCPrimaryButtonStyle() }

    static func scPrimary(fontSize: CGFloat = 15, isEnabled: Bool = true) -> SCPrimaryButtonStyle {
        SCPrimaryButtonStyle(fontSize: fontSize, isEnabled: isEnabled)
    }
}

extension ButtonStyle where Self == SCSecondaryButtonStyle {
    static var scSecondary: SCSecondaryButtonStyle { SCSecondaryButtonStyle() }

    static func scSecondary(fontSize: CGFloat = 15) -> SCSecondaryButtonStyle {
        SCSecondaryButtonStyle(fontSize: fontSize)
    }
}

/// The scrim-backed round icon button the canvas floats over imagery
/// (SpotDetail's back and bookmark controls) and over the map.
struct SCCircleIconButton: View {
    let systemImage: String
    var accessibilityTitle: String
    var diameter: CGFloat = 44
    var background: Color = SCColor.backgroundDeep.opacity(0.75)
    var foreground: Color = SCColor.textPrimary
    var borderColor: Color?
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: diameter * 0.45, weight: .semibold))
                .foregroundStyle(foreground)
                .frame(width: diameter, height: diameter)
                .background(background)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(borderColor ?? .clear, lineWidth: borderColor == nil ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityTitle)
    }
}

#Preview {
    VStack(spacing: 16) {
        Button("Continue") {}.buttonStyle(.scPrimary)
        Button("Sign in") {}.buttonStyle(.scPrimary(fontSize: 14, isEnabled: false))
        Button("Continue with Google") {}.buttonStyle(.scSecondary)
        HStack(spacing: 12) {
            SCCircleIconButton(systemImage: "chevron.left", accessibilityTitle: "Back") {}
            SCCircleIconButton(systemImage: "bookmark", accessibilityTitle: "Bookmark") {}
            SCCircleIconButton(
                systemImage: "location",
                accessibilityTitle: "Center on my location",
                diameter: 50,
                background: SCColor.background,
                borderColor: SCColor.border
            ) {}
        }
    }
    .padding()
    .background(SCColor.background)
}
