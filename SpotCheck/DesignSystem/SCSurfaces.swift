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

/// The canvas's `label … value` row, used by every money card it draws
/// (FilmBooking's PAYMENT, ProReply's payout, Checkout's PRICE,
/// TransactionDetail's BREAKDOWN, Payouts' HOW YOU'RE PAID).
///
/// `isTotal` is the canvas's final-row treatment: the label goes bold
/// where the rows above it are regular weight.
struct SCDetailRow: View {
    let label: String
    let value: String
    var isTotal: Bool = false
    var valueColor: Color = SCColor.textPrimary

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 14, weight: isTotal ? .bold : .regular))
                .foregroundStyle(isTotal ? SCColor.textPrimary : SCColor.textBody)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(valueColor)
        }
    }
}

/// A card row led by a tinted 40pt icon tile, with a title, a muted
/// subtitle and an optional trailing accessory. The canvas uses it for
/// saved payment methods, the payout bank account and tax details, and
/// the receipt's download/help actions.
struct SCIconDetailRow<Trailing: View>: View {
    let systemImage: String
    let title: String
    var subtitle: String?
    @ViewBuilder var trailing: () -> Trailing

    init(
        systemImage: String,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.systemImage = systemImage
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(SCColor.accent)
                .frame(width: 40, height: 40)
                .background(SCColor.border)
                .clipShape(RoundedRectangle(cornerRadius: SCRadius.control))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(SCColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12.5))
                        .foregroundStyle(SCColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            trailing()
        }
        .padding(14)
        .scCard(cornerRadius: SCRadius.cardSmall)
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
