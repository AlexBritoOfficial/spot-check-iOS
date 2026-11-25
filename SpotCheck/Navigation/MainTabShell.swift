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
    @State private var filmingRequestsStore = FilmingRequestsStore()
    @State private var presenceService = PresenceService()
    @State private var menuCoordinator = MenuCoordinator()
    @State private var modeCoordinator = ModeCoordinator()

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
                    SCBottomNavBar(
                        selection: $selection,
                        tabs: MainTab.tabs(for: modeCoordinator.activeMode)
                    ) {
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
        .environment(filmingRequestsStore)
        .environment(presenceService)
        .environment(menuCoordinator)
        .environment(modeCoordinator)
        .onChange(of: selection) { _, newValue in
            visited.insert(newValue)
        }
        // A capability can be revoked or paused while the app is open, and a
        // mode restored from UserDefaults may no longer be granted, so the
        // stored mode is validated against the live set rather than trusted.
        .onChange(of: authManager.currentCapabilities, initial: true) { _, capabilities in
            modeCoordinator.reconcile(with: capabilities)
        }
        .onChange(of: modeCoordinator.activeMode) { _, newMode in
            // FEED and DISCOVER occupy the same slot, so a mode switch can
            // leave `selection` pointing at a tab the new bar doesn't show.
            let tabs = MainTab.tabs(for: newMode)
            if !tabs.contains(selection) {
                selection = .map
                visited.insert(.map)
            }
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
            // Passed explicitly: this modifier sits outside the
            // `.environment(...)` calls above, so its content can't rely on
            // inheriting them.
            drawerDestination(destination)
                .environment(spotsStore)
                .environment(filmingRequestsStore)
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
            if visited.contains(.discover) {
                DiscoverScreen().tabVisible(selection == .discover)
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
        // Earnings owns the push to Payouts, so this one row reaches both.
        case .filmerTools: EarningsScreen()
        case .filmingRequests: DiscoverScreen()
        case .scoutSkaters: IndustryScoutScreen()
        case .requestFilmer:
            FilmBookingScreen(pinCoordinate: locationService.coordinate ?? LocationService.defaultCoordinate)
        case .myRequests:
            MyRequestsScreen(pinCoordinate: locationService.coordinate ?? LocationService.defaultCoordinate)
        case .verifyID: IDVerifyScreen()
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
