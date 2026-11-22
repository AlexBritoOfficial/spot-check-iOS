import SwiftUI

/// The canvas's teardrop pin mark, traced from its SVG path (80x104
/// viewBox) rather than approximated with `mappin.circle.fill` -- it's
/// the brand mark, and it appears inline at sizes down to 10px (Feed
/// clip cards, PostClip's spot tag) where an SF Symbol reads wrong.
struct SCPinShape: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 80
        let sy = rect.height / 104
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy)
        }

        var path = Path()
        path.move(to: p(40, 4))
        path.addCurve(to: p(4, 40), control1: p(20.1, 4), control2: p(4, 20.1))
        path.addCurve(to: p(19.9, 75.2), control1: p(4, 53.6), control2: p(11.6, 64.6))
        path.addLine(to: p(40, 100))
        path.addLine(to: p(60.1, 75.2))
        path.addCurve(to: p(76, 40), control1: p(68.4, 64.6), control2: p(76, 53.6))
        path.addCurve(to: p(40, 4), control1: p(76, 20.1), control2: p(59.9, 4))
        path.closeSubpath()
        return path
    }
}

struct SCPinGlyph: View {
    var height: CGFloat = 39
    var fill: Color = SCColor.accent
    /// The canvas draws a `#15181f` hole in the pin's head on the
    /// selected/brand variants, and leaves it solid on feed/inline uses.
    var showsHole: Bool = false
    var strokeColor: Color?

    private var width: CGFloat { height * 80 / 104 }

    var body: some View {
        SCPinShape()
            .fill(fill)
            .overlay {
                if let strokeColor {
                    SCPinShape().stroke(strokeColor, lineWidth: height * 6 / 104)
                }
            }
            .overlay {
                if showsHole {
                    Circle()
                        .fill(SCColor.background)
                        .frame(width: height * 24 / 104, height: height * 24 / 104)
                        .offset(y: -height * (52 - 39) / 104)
                }
            }
            .frame(width: width, height: height)
    }
}

#Preview {
    HStack(alignment: .bottom, spacing: 20) {
        SCPinGlyph(height: 13)
        SCPinGlyph(height: 39, showsHole: true)
        SCPinGlyph(height: 55, fill: SCColor.pinDefault, strokeColor: SCColor.background)
        SCPinGlyph(height: 110, showsHole: true, strokeColor: SCColor.backgroundDeep)
    }
    .padding()
    .background(SCColor.backgroundDeep)
}
