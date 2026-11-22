import SwiftUI

/// The canvas's `Bookmarks` artboard: its own header with a spot count,
/// and 72pt-thumbnail cards -- dashed-bordered for your own private
/// spots.
struct BookmarksScreen: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(SpotsStore.self) private var spotsStore
    @Environment(BookmarksStore.self) private var bookmarksStore
    @Environment(\.dismiss) private var dismiss

    @State private var isLoading = false
    @State private var spotIDForDetail: UUID?

    private var savedSpots: [Spot] {
        bookmarksStore.bookmarkedSpotIDs.compactMap { spotsStore.spot(id: $0) }
    }

    /// Live filter, not stored rows: per the web app's domain rules, a
    /// spot's own owner never has a Bookmark row for it. "Private spots"
    /// here is just "spots I own that aren't public."
    private var privateOwnedSpots: [Spot] {
        guard let userID = authManager.currentProfile?.id else { return [] }
        return spotsStore.allCachedSpots.filter { $0.isOwned(by: userID) && !$0.isPublic }
    }

    private var totalCount: Int { savedSpots.count + privateOwnedSpots.count }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                if totalCount == 0, !isLoading {
                    ContentUnavailableView(
                        "No bookmarks yet",
                        systemImage: "bookmark",
                        description: Text("Bookmark a spot from its detail page to see it here.")
                    )
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            if !savedSpots.isEmpty {
                                Text("SAVED").scSectionLabel()
                                ForEach(savedSpots) { spot in
                                    row(for: spot, isPrivate: false)
                                }
                            }

                            if !privateOwnedSpots.isEmpty {
                                Text("YOUR PRIVATE SPOTS")
                                    .scSectionLabel()
                                    .padding(.top, 14)
                                ForEach(privateOwnedSpots) { spot in
                                    row(for: spot, isPrivate: true)
                                }
                            }
                        }
                        .padding(SCMetric.screenPadding)
                    }
                    .refreshable { await load() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(SCColor.background)
            .toolbar(.hidden)
            .task { await load() }
            .navigationDestination(item: $spotIDForDetail) { id in
                SpotDetailScreen(spotID: id)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(SCColor.textPrimary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            Text("Bookmarks")
                .font(SCFont.heading(22))
                .foregroundStyle(SCColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(totalCount == 1 ? "1 spot" : "\(totalCount) spots")
                .font(.system(size: 13))
                .foregroundStyle(SCColor.textSecondary)
        }
        .padding(.leading, 10)
        .padding(.trailing, SCMetric.screenPadding)
        .padding(.top, SCMetric.headerTop(52))
        .padding(.bottom, 14)
        .overlay(alignment: .bottom) { SCColor.border.frame(height: 1) }
    }

    private func row(for spot: Spot, isPrivate: Bool) -> some View {
        Button {
            spotIDForDetail = spot.id
        } label: {
            HStack(spacing: 14) {
                SCMediaPlaceholder(cornerRadius: 10)
                    .frame(width: 72, height: 72)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(spot.name)
                            .font(SCFont.headingFixed(16))
                            .foregroundStyle(SCColor.textPrimary)
                        Spacer()
                        if isPrivate {
                            HStack(spacing: 4) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 10))
                                Text("PRIVATE")
                                    .font(SCFont.headingFixed(10))
                            }
                            .foregroundStyle(SCColor.textSecondary)
                        } else if let distance = spot.distanceMeters {
                            Text(String(format: "%.1f mi", distance / 1609.34))
                                .font(.system(size: 12.5))
                                .foregroundStyle(SCColor.textSecondary)
                        }
                    }

                    if let description = spot.description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 13))
                            .foregroundStyle(SCColor.textSecondary)
                            .lineLimit(1)
                    }

                    HStack(spacing: 6) {
                        Badge(text: spot.spotType.rawValue)
                        Badge.difficulty(spot.difficulty)
                    }
                }
            }
            .padding(12)
            .background(SCColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: SCRadius.card)
                    .strokeBorder(
                        isPrivate ? SCColor.textSecondary : SCColor.border,
                        style: StrokeStyle(lineWidth: 1, dash: isPrivate ? [5, 4] : [])
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: SCRadius.card))
        }
        .buttonStyle(.plain)
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        guard let userID = authManager.currentProfile?.id else { return }

        await bookmarksStore.load(userID: userID)

        let repository = SpotsRepository()
        async let bookmarked = try? repository.byIDs(Array(bookmarksStore.bookmarkedSpotIDs))
        async let owned = try? repository.ownedBy(userID: userID)
        let (bookmarkedSpots, ownedSpots) = await (bookmarked, owned)

        spotsStore.ingest(bookmarkedSpots ?? [])
        spotsStore.ingest(ownedSpots ?? [])
    }
}
