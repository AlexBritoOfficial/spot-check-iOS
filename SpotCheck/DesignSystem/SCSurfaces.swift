import SwiftUI

/// Card chrome from the canvas: `#20242c` fill, 1px `#2d333d` border,
/// 14-16px radius. Used by every card, list row and tray in the newer
/// screens.
private struct CardChrome: ViewModifier {
    let cornerRadius: CGFloat
    let fill: Color
    let borderColor: Color
    let borderWidth: CGFloat

    func body(content: Content) -> some View {
        content
            .background(fill)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    func scCard(
        cornerRadius: CGFloat = SCRadius.card,
        fill: Color = SCColor.surface,
        borderColor: Color = SCColor.border,
        borderWidth: CGFloat = 1
    ) -> some View {
        modifier(
            CardChrome(
                cornerRadius: cornerRadius,
                fill: fill,
                borderColor: borderColor,
                borderWidth: borderWidth
            )
        )
    }
}

/// One cell of the canvas's 3-up metric grids (SpotDetail's bust rate,
/// SkaterPortfolio's visit counts, Earnings).
struct SCStatTile: View {
    let value: String
    let label: String
    var valueColor: Color = SCColor.textPrimary

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(SCFont.headingFixed(18))
                .foregroundStyle(valueColor)
            Text(label)
                .font(.system(size: 11.5))
                .foregroundStyle(SCColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .scCard(cornerRadius: SCRadius.control)
    }
}

/// The tinted advisory block the canvas uses for trust/safety copy
/// (ProApply's background-check note, PostClip's GPS-stripping note):
/// a 10%-tint fill with a matching border.
struct SCCallout<Content: View>: View {
    enum Tone {
        case accent, success, danger, neutral

        var color: Color {
            switch self {
            case .accent: SCColor.accent
            case .success: SCColor.success
            case .danger: SCColor.danger
            case .neutral: SCColor.textSecondary
            }
        }
    }

    var tone: Tone = .accent
    var systemImage: String?
    var cornerRadius: CGFloat = SCRadius.card
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(tone.color)
            }
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .scCard(
            cornerRadius: cornerRadius,
            fill: tone.color.opacity(0.1),
            borderColor: tone.color.opacity(tone == .accent ? 1 : 0.35),
            borderWidth: tone == .accent ? 1.5 : 1
        )
    }
}

/// The diagonal hatch the canvas uses wherever a photo or clip would
/// load, with the dark circular play badge on video placeholders.
struct SCMediaPlaceholder: View {
    var cornerRadius: CGFloat = SCRadius.control
    var showsPlayBadge: Bool = false
    var label: String?

    var body: some View {
        ZStack {
            Canvas { context, size in
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .color(SCColor.surfaceAlt)
                )
                let band: CGFloat = 8
                var offset = -size.height
                while offset < size.width + size.height {
                    var stripe = Path()
                    stripe.move(to: CGPoint(x: offset, y: 0))
                    stripe.addLine(to: CGPoint(x: offset + size.height, y: size.height))
                    context.stroke(stripe, with: .color(SCColor.surface), lineWidth: band)
                    offset += band * 2
                }
            }

            if let label {
                Text(label)
                    .font(SCFont.headingFixed(12))
                    .tracking(1.5)
                    .foregroundStyle(SCColor.textSecondary)
            }

            if showsPlayBadge {
                Circle()
                    .fill(SCColor.backgroundDeep.opacity(0.8))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(SCColor.textPrimary)
                    )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

/// The 9.5-10.5px pill the canvas uses for inline markers (challenge
/// entry, "FRESH PICK", role tags in the Menu). Smaller and flatter
/// than `Badge`, which is the bordered spot-type/difficulty tag.
struct SCTag: View {
    let text: String
    var foreground: Color = SCColor.background
    var background: Color = SCColor.accent
    var size: CGFloat = 10

    var body: some View {
        Text(text.uppercased())
            .font(SCFont.headingFixed(size))
            .foregroundStyle(foreground)
            .padding(.horizontal, 7)
            .padding(.vertical, 2.5)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: SCRadius.badge))
    }
}

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                SCStatTile(value: "[X]%", label: "Overall")
                SCStatTile(value: "2", label: "Industry visits", valueColor: SCColor.accent)
                SCStatTile(value: "[N]", label: "Clip views")
            }

            SCCallout(tone: .success, systemImage: "checkmark.shield") {
                Text("Every filmer passes a background check.")
                    .font(.system(size: 13.5))
                    .foregroundStyle(SCColor.textBody)
            }

            SCMediaPlaceholder(showsPlayBadge: true)
                .aspectRatio(4.0 / 5.0, contentMode: .fit)
                .frame(width: 140)

            SCMediaPlaceholder(label: "SPOT PHOTO")
                .frame(height: 120)

            HStack(spacing: 6) {
                SCTag(text: "Flip in, flip out")
                SCTag(text: "Fresh pick", background: SCColor.success)
                SCTag(text: "Filmers", foreground: SCColor.textSecondary, background: SCColor.border, size: 9.5)
            }
        }
        .padding()
    }
    .background(SCColor.background)
}
