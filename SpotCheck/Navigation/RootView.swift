import SwiftUI

struct RootView: View {
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        switch authManager.state {
        case .loading:
            ProgressView()
        case .signedOut:
            LoginView()
        case .signedIn:
            SignedInTabView()
        }
    }
}

private struct SignedInTabView: View {
    @State private var spotsStore = SpotsStore()
    @State private var bookmarksStore = BookmarksStore()
    @State private var presenceService = PresenceService()

    var body: some View {
        TabView {
            MapScreen()
                .tabItem { Label("Map", systemImage: "map") }
            BookmarksScreen()
                .tabItem { Label("Saved", systemImage: "bookmark") }
            MessagesScreen()
                .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right") }
            MenuScreen()
                .tabItem { Label("Menu", systemImage: "line.3.horizontal") }
        }
        .environment(spotsStore)
        .environment(bookmarksStore)
        .environment(presenceService)
    }
}

#Preview {
    RootView()
        .environment(AuthManager())
}
