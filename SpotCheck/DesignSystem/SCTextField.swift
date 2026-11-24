import SwiftUI

/// The labeled, filled text field used on Login/Signup/AddSpot/Booking.
///
/// Renders its own placeholder as a plain overlaid Text rather than
/// using TextField's native placeholder/prompt: iOS recolors a native
/// placeholder to system blue for `.emailAddress` (and similar) content
/// types at a level below SwiftUI's `foregroundStyle`, so that's the
/// only reliable way to keep it the muted gray the design calls for.
struct SCTextField<Accessory: View>: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var contentType: UITextContentType?
    var keyboard: UIKeyboardType = .default
    var isSecure: Bool = false
    @ViewBuilder var labelAccessory: () -> Accessory

    @State private var isRevealed = false

    init(
        label: String,
        placeholder: String,
        text: Binding<String>,
        contentType: UITextContentType? = nil,
        keyboard: UIKeyboardType = .default,
        isSecure: Bool = false,
        @ViewBuilder labelAccessory: @escaping () -> Accessory = { EmptyView() }
    ) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.contentType = contentType
        self.keyboard = keyboard
        self.isSecure = isSecure
        self.labelAccessory = labelAccessory
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label.uppercased()).scFieldLabel()
                Spacer()
                labelAccessory()
            }
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(SCFont.headingFixed(15))
                        .foregroundStyle(SCColor.textSecondary)
                        .padding(.horizontal, 16)
                        .allowsHitTesting(false)
                }

                Group {
                    if isSecure && !isRevealed {
                        SecureField("", text: $text)
                    } else {
                        TextField("", text: $text)
                    }
                }
                .textContentType(contentType)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .scTextFieldTextStyle()
                .padding(.trailing, isSecure ? 44 : 0)

                if isSecure {
                    HStack {
                        Spacer()
                        Button {
                            isRevealed.toggle()
                        } label: {
                            Image(systemName: isRevealed ? "eye.slash" : "eye")
                                .foregroundStyle(SCColor.textSecondary)
                        }
                        .accessibilityLabel(isRevealed ? "Hide password" : "Show password")
                        .padding(.trailing, 16)
                    }
                }
            }
            .scFieldContainerChrome()
        }
    }
}

#Preview {
    @Previewable @State var email = ""
    @Previewable @State var password = ""
    return VStack(spacing: 16) {
        SCTextField(label: "Email", placeholder: "you@example.com", text: $email, contentType: .emailAddress, keyboard: .emailAddress)
        SCTextField(label: "Password", placeholder: "••••••••", text: $password, contentType: .password, isSecure: true)
    }
    .padding()
    .background(SCColor.background)
}
