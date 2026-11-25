@preconcurrency import StripeIdentity
import UIKit

/// The one place StripeIdentity is touched: presents Stripe's sheet and
/// reports how it closed in IdentityVerificationFlow's terms.
///
/// The web-based sheet, initialised from the VerificationSession's client
/// secret -- exactly what `identity-session` returns. The native variant
/// needs an ephemeral key Stripe issues by invitation only, so it isn't used.
/// No publishable key is involved either: the client secret is enough.
@MainActor
enum StripeIdentitySheet {
    static func present(clientSecret: String) async -> IdentityVerificationFlow.SheetOutcome {
        guard let presenter = UIApplication.shared.topmostViewController else {
            return .failed(message: unavailableMessage)
        }
        // The sheet keeps itself alive until its completion runs.
        let sheet = IdentityVerificationSheet(verificationSessionClientSecret: clientSecret)
        return await withCheckedContinuation { continuation in
            sheet.present(from: presenter) { result in
                switch result {
                case .flowCompleted:
                    continuation.resume(returning: .completed)
                case .flowCanceled:
                    continuation.resume(returning: .canceled)
                case .flowFailed:
                    // Stripe's error descriptions are written for developers
                    // ("invalidClientSecret"), so the user gets a plain line.
                    continuation.resume(returning: .failed(message: unavailableMessage))
                }
            }
        }
    }

    private static let unavailableMessage = "Verification couldn't open. Try again."
}

private extension UIApplication {
    /// Whatever is on top right now -- IDVerifyScreen is itself presented as
    /// a sheet, and Stripe's sheet must go over it, not under it.
    var topmostViewController: UIViewController? {
        let window = connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        var top = window?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
