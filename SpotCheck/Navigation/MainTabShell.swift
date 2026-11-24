import SwiftUI

/// Hosts the four canvas destinations behind `SCBottomNavBar`, plus the
/// slide-out menu and the raised post-a-clip action.
///
/// Tabs are kept alive once visited rather than rebuilt on every switch,
/// which is how the system `TabView` this replaced behaved -- switching
/// away and back shouldn't refetch a tab's data.
struct MainTabShell: View {
    @Environment(AuthManager.self) private var authManager

    @State private var spotsStore = SpotsStore()
    @State private var bookmarksStore = BookmarksStore()
    @State private var presenceService = PresenceService()
    @State private var menuCoordinator = MenuCoordinator()

    @State private var locationService = LocationService()
    @State private var selection: MainTab = .map
    @State private var visited: Set<MainTab> = [.map]
    @State private var showPostClip = false
    @State private var showAddSpot = false
    @State private var isAddSpotQueued = false

    var body: some View {
        ZStack(alignment: .leading) {
            tabs
                .overlay(alignment: .bottom) {
                    SCBottomNavBar(selection: $selection) {
                        showPostClip = true
                    }
                    .background(SCColor.background.ignoresSafeArea(edges: .bottom))
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
                        selection = .profile
                        visited.insert(.profile)
                    },
                    onSelectMessages: {
                        menuCoordinator.isOpen = false
                        selection = .chat
                        visited.insert(.chat)
                    },
                    onSelect: { destination in
                        menuCoordinator.isOpen = false
                        menuCoordinator.destination = destination
                    },
                    onSignOut: {
                        menuCoordinator.isOpen = false
                        Task { await authManager.signOut() }
                    }
                )
                .transition(.move(edge: .leading))
            }
        }
        .animation(.easeOut(duration: 0.25), value: menuCoordinator.isOpen)
        .background(SCColor.background)
        .environment(spotsStore)
        .environment(bookmarksStore)
        .environment(presenceService)
        .environment(menuCoordinator)
        .onChange(of: selection) { _, newValue in
            visited.insert(newValue)
        }
        .sheet(isPresented: $showPostClip, onDismiss: {
            if isAddSpotQueued {
                isAddSpotQueued = false
                showAddSpot = true
            }
        }) {
            PostClipScreen {
                isAddSpotQueued = true
                showPostClip = false
            }
        }
        .sheet(isPresented: $showAddSpot) {
            AddSpotScreen(
                initialCoordinate: locationService.coordinate ?? LocationService.defaultCoordinate
            )
        }
        .sheet(item: $menuCoordinator.destination) { destination in
            drawerDestination(destination)
        }
    }

    private var tabs: some View {
        ZStack {
            if visited.contains(.map) {
                MapScreen().tabVisible(selection == .map)
            }
            if visited.contains(.feed) {
                FeedScreen().tabVisible(selection == .feed)
            }
            if visited.contains(.chat) {
                MessagesScreen().tabVisible(selection == .chat)
            }
            if visited.contains(.profile) {
                SkaterPortfolioScreen().tabVisible(selection == .profile)
            }
        }
    }

    @ViewBuilder
    private func drawerDestination(_ destination: MenuCoordinator.Destination) -> some View {
        switch destination {
        case .bookmarks: BookmarksScreen()
        case .opportunities: OpportunitiesScreen()
        // TransactionsScreen pushes its receipt, and doesn't own a stack so
        // that PayoutsScreen can push it too.
        case .transactions: NavigationStack { TransactionsScreen() }
        case .becomeFilmer: ProApplyScreen()
        case .filmingRequests: DiscoverScreen()
        case .scoutSkaters: IndustryScoutScreen()
        }
    }
}

private extension View {
    func tabVisible(_ isVisible: Bool) -> some View {
        opacity(isVisible ? 1 : 0)
            .allowsHitTesting(isVisible)
            .accessibilityHidden(!isVisible)
    }
}
