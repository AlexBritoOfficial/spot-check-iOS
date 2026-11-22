import SwiftUI

struct RootView: View {
    /// Session restore usually resolves in well under a second, which
    /// flashes the splash rather than showing it. Hold it for at least
    /// this long so the wordmark actually reads.
    private static let minimumSplashDuration: Duration = .seconds(1.8)

    @Environment(AuthManager.self) private var authManager
    @State private var splashHoldElapsed = false

    private var isRestoringSession: Bool {
        if case .loading = authManager.state { return true }
        return false
    }

    var body: some View {
        Group {
            if isRestoringSession || !splashHoldElapsed {
                SplashScreen()
                    .transition(.opacity)
            } else {
                switch authManager.state {
                case .loading:
                    SplashScreen()
                case .signedOut:
                    LoginView()
                case .signedIn:
                    MainTabShell()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: splashHoldElapsed)
        .task {
            try? await Task.sleep(for: Self.minimumSplashDuration)
            splashHoldElapsed = true
        }
    }
}

#Preview {
    RootView()
        .environment(AuthManager())
}
