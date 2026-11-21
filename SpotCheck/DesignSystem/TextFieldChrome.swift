import SwiftUI

/// Font/color/sizing only -- no background. Applied to the TextField
/// itself; the opaque fill goes on the container (see
/// `scFieldContainerChrome`), since putting it directly on the field
/// would paint over a placeholder Text sitting behind it in a ZStack.
private struct TextFieldTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(SCFont.headingFixed(15))
            .foregroundStyle(SCColor.textPrimary)
            .tint(SCColor.accent)
            .padding(.horizontal, 16)
            .frame(height: SCMetric.controlHeight)
    }
}

/// The filled, borderless chrome used for every input's container in
/// the canvas (Login/Signup/AddSpot/Booking): 52px tall, #2d333d fill,
/// 12px radius.
private struct FieldContainerChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(height: SCMetric.controlHeight)
            .background(SCColor.inputFill)
            .clipShape(RoundedRectangle(cornerRadius: SCRadius.control))
    }
}

/// The small Archivo Black field label above each input.
private struct FieldLabelStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(SCFont.headingFixed(12))
            .foregroundStyle(SCColor.textSecondary)
    }
}

extension View {
    func scTextFieldTextStyle() -> some View {
        modifier(TextFieldTextStyle())
    }

    func scFieldContainerChrome() -> some View {
        modifier(FieldContainerChrome())
    }

    func scFieldLabel() -> some View {
        modifier(FieldLabelStyle())
    }
}
