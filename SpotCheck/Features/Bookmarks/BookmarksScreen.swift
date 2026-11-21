import SwiftUI

struct BookmarksScreen: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(SpotsStore.self) private var spotsStore
    @Environment(BookmarksStore.self) private var bookmarksStore

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
            Group {
                if totalCount == 0, !isLoading {
                    ContentUnavailableView(
                        "No bookmarks yet",
                        systemImage: "bookmark",
                        description: Text("Bookmark a spot from its detail page to see it here.")
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            if !savedSpots.isEmpty {
                                section(title: "SAVED", spots: savedSpots)
                            }
                            if !privateOwnedSpots.isEmpty {
                                section(title: "YOUR PRIVATE SPOTS", spots: privateOwnedSpots, dashed: true)
                            }
                        }
                        .padding(20)
                    }
                    .background(SCColor.background)
                    .refreshable { await load() }
                }
            }
            .background(SCColor.background)
            .navigationTitle("Bookmarks")
            .toolbarBackground(SCColor.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("\(totalCount) spots")
                        .font(.system(size: 13))
                        .foregroundStyle(SCColor.textSecondary)
                }
            }
            .task { await load() }
            .navigationDestination(item: $spotIDForDetail) { id in
                SpotDetailScreen(spotID: id)
            }
        }
    }

    private func section(title: String, spots: [Spot], dashed: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).scFieldLabel()
            ForEach(spots) { spot in
                row(for: spot, dashed: dashed)
            }
        }
    }

    private func row(for spot: Spot, dashed: Bool) -> some View {
        Button {
            spotIDForDetail = spot.id
        } label: {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: SCRadius.control - 2)
                    .fill(SCColor.border)
                    .frame(width: 72, height: 72)
                    .overlay(Image(systemName: "photo").foregroundStyle(SCColor.textSecondary))

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(spot.name)
                            .font(SCFont.headingFixed(16))
                            .foregroundStyle(SCColor.textPrimary)
                        Spacer()
                        if !spot.isPublic {
                            Label("PRIVATE", systemImage: "lock.fill")
                                .font(SCFont.headingFixed(10))
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
                    .strokeBorder(dashed ? SCColor.textSecondary : SCColor.border, style: StrokeStyle(lineWidth: 1, dash: dashed ? [5, 4] : []))
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
