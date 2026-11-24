import SwiftUI

/// The canvas's `PaymentStatus` artboard. The artboard is driven by a
/// status prop with three variants, so `status` carries the same three
/// cases and all three are previewed.
///
/// "Held" is the normal outcome, not "paid": Spot Check holds the money
/// between the filmer accepting and both sides confirming the session.
struct PaymentStatusScreen: View {
    enum Status {
        case processing, held, declined
    }

    private enum Route: Hashable {
        case receipt, paymentMethods
    }

    var status: Status = .held
    /// The canvas names the filmer in both the held and declined copy.
    var filmerName: String = "Rider Okafor"
    /// Opening the thread needs the filmer's conversation and user IDs, which
    /// arrive with the payments schema -- `ChatScreen` takes real UUIDs and
    /// there is nothing to pass yet, so the presenter supplies this.
    var onMessageFilmer: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    @State private var route: Route?

    var body: some View {
        content
            .toolbar(.hidden)
            .navigationDestination(item: $route) { route in
                switch route {
                case .receipt: TransactionDetailScreen()
                case .paymentMethods: PaymentMethodsScreen()
                }
            }
    }

    private var content: some View {
        VStack(spacing: 0) {
            closeRow

            switch status {
            case .processing:
                processing
            case .held:
                outcome(
                    tint: SCColor.success,
                    systemImage: "checkmark",
                    title: "Payment held",
                    body: "\(filmerName) accepted your request. We're holding $[TOTAL] and release it after you both confirm the session."
                ) {
                    SCDetailRow(label: "Amount held", value: "$[TOTAL]", isTotal: true)
                    SCDetailRow(label: "Paid with", value: "Visa •••• 4242")
                    SCDetailRow(label: "Session", value: "Sat, Nov 28 · 5–7 PM")
                }

                SCFooterBar {
                    VStack(spacing: 10) {
                        Button("View receipt") { route = .receipt }
                            .buttonStyle(.scPrimary(fontSize: 14.5))
                        Button("Message \(filmerName)", action: onMessageFilmer)
                            .buttonStyle(.scSecondary(fontSize: 14.5))
                    }
                }
            case .declined:
                outcome(
                    tint: SCColor.danger,
                    systemImage: "xmark",
                    title: "Card declined",
                    body: "Your bank declined the $[TOTAL] charge, so the booking isn't confirmed yet. Use another payment method to keep it."
                ) {
                    SCDetailRow(label: "Tried", value: "Visa •••• 4242")
                    SCDetailRow(label: "Reason from bank", value: "Insufficient funds")
                    SCNoteRow(text: "Nothing was charged.", systemImage: "info.circle")
                }

                SCFooterBar {
                    VStack(spacing: 10) {
                        Button("Update payment method") { route = .paymentMethods }
                            .buttonStyle(.scPrimary(fontSize: 14.5))
                        Button("Cancel request") { dismiss() }
                            .buttonStyle(.scSecondary(fontSize: 14.5))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
    }

    private var closeRow: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(SCColor.textPrimary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.top, SCMetric.headerTop(52))
    }

    private var processing: some View {
        VStack(spacing: 18) {
            SpinnerRing()
            Text("Processing payment")
                .font(SCFont.heading(24))
                .foregroundStyle(SCColor.textPrimary)
                .multilineTextAlignment(.center)
            Text("Charging Visa •••• 4242 for $[TOTAL]. Keep the app open for a moment.")
                .font(.system(size: 15))
                .lineSpacing(4)
                .foregroundStyle(SCColor.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 36)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func outcome<Details: View>(
        tint: Color,
        systemImage: String,
        title: String,
        body: String,
        @ViewBuilder details: () -> Details
    ) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(tint)
                    .frame(width: 72, height: 72)
                    .background(tint.opacity(0.15))
                    .clipShape(Circle())

                Text(title)
                    .font(SCFont.heading(24))
                    .foregroundStyle(SCColor.textPrimary)
                    .multilineTextAlignment(.center)

                Text(body)
                    .font(.system(size: 15))
                    .lineSpacing(4)
                    .foregroundStyle(SCColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 24)

            VStack(alignment: .leading, spacing: 10) {
                details()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .scCard(cornerRadius: SCRadius.cardSmall)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

/// The canvas draws a static three-quarter ring; a live screen spins it.
private struct SpinnerRing: View {
    @State private var isSpinning = false

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.25)
            .stroke(SCColor.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
            .background {
                Circle().stroke(SCColor.border, lineWidth: 5)
            }
            .frame(width: 72, height: 72)
            .rotationEffect(.degrees(isSpinning ? 360 : 0))
            .animation(.linear(duration: 0.9).repeatForever(autoreverses: false), value: isSpinning)
            .onAppear { isSpinning = true }
            .accessibilityLabel("Processing")
    }
}

#Preview("Processing") {
    NavigationStack {
        PaymentStatusScreen(status: .processing)
    }
}

#Preview("Held") {
    NavigationStack {
        PaymentStatusScreen(status: .held)
    }
}

#Preview("Declined") {
    NavigationStack {
        PaymentStatusScreen(status: .declined)
    }
}
