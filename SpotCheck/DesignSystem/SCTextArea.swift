import SwiftUI

/// The canvas's filled multi-line input (`#2d333d` fill, 12px radius,
/// 15px copy), used by PostClip, SendOpportunity, Rating, ProRequest,
/// ProReply and Report. Draws its own placeholder as overlaid `Text`
/// for the same reason `SCTextField` does.
struct SCTextArea: View {
    let placeholder: String
    @Binding var text: String
    var rows: Int = 3
    var accessibilityTitle: String?

    private var minHeight: CGFloat { CGFloat(rows) * 20 + 24 }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.system(size: 15))
                    .foregroundStyle(SCColor.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .font(.system(size: 15))
                .foregroundStyle(SCColor.textPrimary)
                .tint(SCColor.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .frame(minHeight: minHeight)
                .accessibilityLabel(accessibilityTitle ?? placeholder)
        }
        .background(SCColor.inputFill)
        .clipShape(RoundedRectangle(cornerRadius: SCRadius.control))
    }
}

#Preview {
    @Previewable @State var empty = ""
    @Previewable @State var filled = "My kickflips keep flipping late."

    return VStack(spacing: 16) {
        SCTextArea(
            placeholder: "e.g. My kickflips keep flipping late. What am I doing wrong?",
            text: $empty,
            rows: 4
        )
        SCTextArea(placeholder: "Or type a text reply", text: $filled)
    }
    .padding(20)
    .background(SCColor.background)
}
