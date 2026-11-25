import SafariServices
import SwiftUI

/// An in-app Safari page, for flows another service hosts -- Stripe's Connect
/// onboarding. SFSafariViewController rather than a web view: the user sees
/// the real address bar and the host's own certificate, which matters on a
/// page that asks for bank details.
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    /// Safari's own Done button. Wired explicitly because SwiftUI's sheet
    /// binding isn't reliably cleared when Safari dismisses itself.
    var onDone: () -> Void = {}

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.dismissButtonStyle = .done
        controller.preferredControlTintColor = UIColor(SCColor.accent)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {
        context.coordinator.onDone = onDone
    }

    func makeCoordinator() -> Coordinator { Coordinator(onDone: onDone) }

    final class Coordinator: NSObject, SFSafariViewControllerDelegate {
        var onDone: () -> Void

        init(onDone: @escaping () -> Void) {
            self.onDone = onDone
        }

        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            onDone()
        }
    }
}
