import Foundation
import Observation

@MainActor
@Observable
final class BookmarksStore {
    private(set) var bookmarkedSpotIDs: Set<UUID> = []
    private(set) var lastError: String?

    private let repository: BookmarksRepository

    init(repository: BookmarksRepository = BookmarksRepository()) {
        self.repository = repository
    }

    func isBookmarked(_ spotID: UUID) -> Bool {
        bookmarkedSpotIDs.contains(spotID)
    }

    func load(userID: UUID) async {
        do {
            let bookmarks = try await repository.list(userID: userID)
            bookmarkedSpotIDs = Set(bookmarks.map(\.spotID))
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Optimistic toggle with revert-on-failure, since this is driven by
    /// a single tap on a bookmark icon that should feel instant.
    func toggle(spotID: UUID, userID: UUID) async {
        let wasBookmarked = bookmarkedSpotIDs.contains(spotID)
        if wasBookmarked {
            bookmarkedSpotIDs.remove(spotID)
        } else {
            bookmarkedSpotIDs.insert(spotID)
        }
        do {
            if wasBookmarked {
                try await repository.remove(userID: userID, spotID: spotID)
            } else {
                try await repository.add(userID: userID, spotID: spotID)
            }
            lastError = nil
        } catch {
            if wasBookmarked {
                bookmarkedSpotIDs.insert(spotID)
            } else {
                bookmarkedSpotIDs.remove(spotID)
            }
            lastError = error.localizedDescription
        }
    }
}
