import SwiftUI

/// The canvas's `Main` artboard, shown while `AuthManager` resolves the
/// stored session. The progress bar is a fixed 45% like the artboard --
/// session restore has no measurable progress to report.
struct SplashScreen: View {
    var body: some View {
        ZStack {
            SCColor.backgroundDeep

            SplashRoadBackdrop()
                .opacity(0.6)
                .accessibilityHidden(true)

            VStack(spacing: 28) {
                brandMark
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Text("SPOT").foregroundStyle(SCColor.textPrimary)
                        Text("CHECK").foregroundStyle(SCColor.accent)
                    }
                    .font(SCFont.headingFixed(44))

                    Text("Find, add and save skate spots.")
                        .font(.system(size: 16))
                        .foregroundStyle(SCColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 60)

            VStack(spacing: 14) {
                Capsule()
                    .fill(SCColor.border)
                    .frame(width: 132, height: 4)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(SCColor.accent)
                            .frame(width: 132 * 0.45, height: 4)
                    }
                Text("FINDING SPOTS NEAR YOU")
                    .font(SCFont.headingFixed(11))
                    .tracking(1.5)
                    .foregroundStyle(SCColor.textSecondary)
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 64)
            .accessibilityElement()
            .accessibilityLabel("Finding spots near you")
        }
        .ignoresSafeArea()
    }

    private var brandMark: some View {
        ZStack {
            Ellipse()
                .stroke(SCColor.accent.opacity(0.35), lineWidth: 2)
                .frame(width: 100, height: 36)
                .offset(y: 52)
            Ellipse()
                .stroke(SCColor.accent.opacity(0.7), lineWidth: 2)
                .frame(width: 56, height: 18)
                .offset(y: 53)
            SCPinGlyph(height: 110, showsHole: true, strokeColor: SCColor.backgroundDeep)
                .offset(y: -16)
        }
        .frame(width: 168, height: 168)
    }
}

/// The faint road grid behind the wordmark, traced from the artboard's
/// background SVG in its own 390x844 space and scaled to fit.
private struct SplashRoadBackdrop: View {
    var body: some View {
        Canvas { context, size in
            let sx = size.width / 390
            let sy = size.height / 844
            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: x * sx, y: y * sy)
            }

            var thick = Path()
            for line in Self.thickLines {
                thick.move(to: point(line.0, line.1))
                thick.addLine(to: point(line.2, line.3))
            }
            thick.move(to: point(-40, 860))
            thick.addCurve(
                to: point(430, 300),
                control1: point(120, 640),
                control2: point(260, 520)
            )
            context.stroke(thick, with: .color(SCColor.border), lineWidth: 2)

            var thin = Path()
            for line in Self.thinLines {
                thin.move(to: point(line.0, line.1))
                thin.addLine(to: point(line.2, line.3))
            }
            context.stroke(thin, with: .color(SCColor.border), lineWidth: 1)

            for dot in Self.dots {
                let rect = CGRect(
                    origin: point(dot.0 - 5, dot.1 - 5),
                    size: CGSize(width: 10 * sx, height: 10 * sy)
                )
                context.fill(Path(ellipseIn: rect), with: .color(SCColor.border))
            }
        }
    }

    private static let thickLines: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
        (-20, 120, 410, 210),
        (-20, 330, 410, 300),
        (-20, 560, 410, 610),
        (-20, 720, 410, 690),
        (70, -20, 110, 864),
        (250, -20, 300, 864)
    ]

    private static let thinLines: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
        (-20, 40, 410, 90),
        (-20, 460, 410, 455),
        (170, -20, 190, 864),
        (340, -20, 360, 864)
    ]

    private static let dots: [(CGFloat, CGFloat)] = [
        (110, 210), (300, 300), (92, 610), (290, 690)
    ]
}

#Preview {
    SplashScreen()
}
