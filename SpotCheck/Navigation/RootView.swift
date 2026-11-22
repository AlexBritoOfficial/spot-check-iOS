import SwiftUI

struct RootView: View {
    @Environment(AuthManager.self) private var authManager

    var body: some View {
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

#Preview {
    RootView()
        .environment(AuthManager())
}
