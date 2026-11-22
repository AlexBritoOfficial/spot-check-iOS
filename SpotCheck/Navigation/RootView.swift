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
    @Environment(AuthManager.self) private var authManager

    @State private var spotsStore = SpotsStore()
    @State private var bookmarksStore = BookmarksStore()
    @State private var presenceService = PresenceService()
    @State private var menuCoordinator = MenuCoordinator()
    @State private var showProfile = false

    var body: some View {
        ZStack(alignment: .leading) {
            TabView {
                MapScreen()
                    .tabItem { Label("Map", systemImage: "map") }
                BookmarksScreen()
                    .tabItem { Label("Saved", systemImage: "bookmark") }
                MessagesScreen()
                    .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right") }
            }

            if menuCoordinator.isOpen {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture { menuCoordinator.isOpen = false }
                    .transition(.opacity)

                MenuScreen(
                    onClose: { menuCoordinator.isOpen = false },
                    onSelectProfile: {
                        menuCoordinator.isOpen = false
                        showProfile = true
                    }
                )
                .transition(.move(edge: .leading))
            }
        }
        .animation(.easeOut(duration: 0.25), value: menuCoordinator.isOpen)
        .environment(spotsStore)
        .environment(bookmarksStore)
        .environment(presenceService)
        .environment(menuCoordinator)
        .fullScreenCover(isPresented: $showProfile) {
            if let id = authManager.currentProfile?.id {
                NavigationStack {
                    SkaterProfileScreen(userID: id)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button("Close") { showProfile = false }
                            }
                        }
                }
            }
        }
    }
}

#Preview {
    RootView()
        .environment(AuthManager())
}
