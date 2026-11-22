import Observation

/// Lets any tab's toolbar open the slide-out menu owned by
/// `SignedInTabView`, without each screen needing its own copy of the
/// drawer state.
@MainActor
@Observable
final class MenuCoordinator {
    var isOpen = false
}
