import Observation

/// Lets any tab's header open the slide-out menu owned by
/// `MainTabShell`, without each screen needing its own copy of the
/// drawer state.
@MainActor
@Observable
final class MenuCoordinator {
    /// The drawer rows that lead somewhere, as the canvas's `Menu`
    /// artboard links them. Rows the canvas leaves pointing at `#`
    /// (Notifications, Settings) have no case here.
    enum Destination: Identifiable {
        case bookmarks
        case opportunities
        case transactions
        case becomeFilmer
        /// Replaces `becomeFilmer` in the drawer once filmer is active.
        case filmerTools
        case filmingRequests
        case scoutSkaters
        /// Not on the canvas's menu: a skater's way into booking a filmer,
        /// and to the requests they've made.
        case requestFilmer
        case myRequests

        var id: Self { self }
    }

    var isOpen = false
    var destination: Destination?
}
