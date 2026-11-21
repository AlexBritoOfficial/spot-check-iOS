import MapKit
import SwiftUI

struct SpotDetailScreen: View {
    let spotID: UUID

    @Environment(SpotsStore.self) private var spotsStore
    @Environment(BookmarksStore.self) private var bookmarksStore
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    @State private var photoURL: URL?
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false

    private var spot: Spot? { spotsStore.spot(id: spotID) }
    private var isOwner: Bool { spot?.isOwned(by: authManager.currentProfile?.id) ?? false }

    var body: some View {
        Group {
            if let spot {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        photoHeader

                        VStack(alignment: .leading, spacing: 16) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(spot.name)
                                    .font(SCFont.heading(28))
                                    .foregroundStyle(SCColor.textPrimary)
                                Spacer()
                                if let distance = spot.distanceMeters {
                                    Text("\(String(format: "%.1f", distance / 1609.34)) mi · \(spot.city)")
                                        .font(.system(size: 14))
                                        .foregroundStyle(SCColor.textSecondary)
                                } else if !spot.city.isEmpty {
                                    Text(spot.city)
                                        .font(.system(size: 14))
                                        .foregroundStyle(SCColor.textSecondary)
                                }
                            }

                            HStack(spacing: 8) {
                                Badge(text: spot.spotType.rawValue)
                                Badge.difficulty(spot.difficulty)
                                if !spot.isPublic {
                                    Badge(text: "Private", color: SCColor.textSecondary)
                                }
                            }

                            HStack(spacing: 8) {
                                Image(systemName: spot.isSkateable ? "checkmark.circle.fill" : "questionmark.circle")
                                    .foregroundStyle(spot.isSkateable ? SCColor.background : SCColor.textSecondary, spot.isSkateable ? SCColor.success : .clear)
                                Text(spot.isSkateable ? "Confirmed skateable" : "Unconfirmed")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(spot.isSkateable ? SCColor.success : SCColor.textSecondary)
                            }

                            if let description = spot.description, !description.isEmpty {
                                Text(description)
                                    .font(.system(size: 16))
                                    .foregroundStyle(SCColor.textBody)
                                    .lineSpacing(4)
                            }

                            if !spot.features.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("FEATURES").scFieldLabel()
                                    HStack(spacing: 8) {
                                        ForEach(spot.features, id: \.self) { feature in
                                            Badge(text: feature.rawValue)
                                        }
                                    }
                                }
                            }

                            StarRating(rating: spot.rating)

                            Button {
                                openDirections(to: spot)
                            } label: {
                                Text("Directions")
                                    .font(SCFont.buttonLabel)
                                    .frame(maxWidth: .infinity)
                            }
                            .frame(height: SCMetric.controlHeight)
                            .background(SCColor.accent)
                            .foregroundStyle(SCColor.background)
                            .clipShape(RoundedRectangle(cornerRadius: SCRadius.control))
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 32)
                }
                .background(SCColor.background)
            } else {
                ProgressView().tint(SCColor.accent)
            }
        }
        .background(SCColor.background)
        .navigationTitle(spot?.name ?? "Spot")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(SCColor.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await toggleBookmark() }
                } label: {
                    Image(systemName: bookmarksStore.isBookmarked(spotID) ? "bookmark.fill" : "bookmark")
                        .foregroundStyle(SCColor.accent)
                }
                .disabled(isOwner)
            }
            if isOwner {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(SCColor.danger)
                    }
                }
            }
        }
        .task { await loadPhoto() }
        .confirmationDialog("Delete this spot?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { Task { await delete() } }
        }
    }

    @ViewBuilder
    private var photoHeader: some View {
        ZStack {
            SCColor.surface
            if let photoURL {
                AsyncImage(url: photoURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    ProgressView().tint(SCColor.accent)
                }
            } else {
                Text("SPOT PHOTO")
                    .font(SCFont.headingFixed(12))
                    .foregroundStyle(SCColor.textSecondary)
            }
        }
        .frame(height: 260)
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private func loadPhoto() async {
        guard let path = spot?.photo else { return }
        photoURL = try? await SpotPhotoStorage.signedURL(path: path)
    }

    private func toggleBookmark() async {
        guard let userID = authManager.currentProfile?.id else { return }
        await bookmarksStore.toggle(spotID: spotID, userID: userID)
    }

    private func delete() async {
        isDeleting = true
        defer { isDeleting = false }
        try? await spotsStore.delete(id: spotID)
        dismiss()
    }

    private func openDirections(to spot: Spot) {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: spot.coordinate))
        mapItem.name = spot.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}
