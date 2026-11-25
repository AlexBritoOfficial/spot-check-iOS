import MapKit
import SwiftUI

/// The canvas's `SpotDetail` artboard: a tall photo with floating
/// controls, a rounded sheet riding over it, and a docked action row.
///
/// Two deliberate departures from the artboard. The owner's delete
/// action has no place in the artboard's header, so it sits in an
/// overflow menu beside the bookmark rather than being dropped. The
/// spot's description isn't on the artboard either, but it's real
/// user-entered content, so it stays. Bust rate shows the artboard's
/// placeholders -- nothing logs sessions yet.
struct SpotDetailScreen: View {
    let spotID: UUID

    @Environment(SpotsStore.self) private var spotsStore
    @Environment(BookmarksStore.self) private var bookmarksStore
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    @State private var photoURL: URL?
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var showBustLog = false
    @State private var showsFilmBooking = false

    private var spot: Spot? { spotsStore.spot(id: spotID) }
    private var isOwner: Bool { spot?.isOwned(by: authManager.currentProfile?.id) ?? false }

    var body: some View {
        Group {
            if let spot {
                ZStack(alignment: .top) {
                    ScrollView {
                        VStack(spacing: 0) {
                            photoHeader
                            details(for: spot)
                        }
                    }
                    .ignoresSafeArea(edges: .top)

                    floatingControls
                }
                .safeAreaInset(edge: .bottom) { actionBar(for: spot) }
            } else {
                ProgressView().tint(SCColor.accent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
        .toolbar(.hidden)
        .task { await loadPhoto() }
        .confirmationDialog("Delete this spot?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { Task { await delete() } }
        }
        .sheet(isPresented: $showBustLog) {
            BustLogScreen()
        }
        .sheet(isPresented: $showsFilmBooking) {
            if let spot {
                FilmBookingScreen(spot: spot)
            }
        }
    }

    private var photoHeader: some View {
        ZStack {
            if let photoURL {
                AsyncImage(url: photoURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    ProgressView().tint(SCColor.accent)
                }
            } else {
                SCMediaPlaceholder(cornerRadius: 0, label: "SPOT PHOTO")
            }
        }
        .frame(height: 330)
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private var floatingControls: some View {
        HStack {
            SCCircleIconButton(
                systemImage: "chevron.left",
                accessibilityTitle: "Back to map"
            ) {
                dismiss()
            }

            Spacer()

            if isOwner {
                Menu {
                    Button("Delete spot", systemImage: "trash", role: .destructive) {
                        showDeleteConfirm = true
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(SCColor.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(SCColor.backgroundDeep.opacity(0.75))
                        .clipShape(Circle())
                }
                .accessibilityLabel("More actions")
            } else {
                SCCircleIconButton(
                    systemImage: bookmarksStore.isBookmarked(spotID) ? "bookmark.fill" : "bookmark",
                    accessibilityTitle: bookmarksStore.isBookmarked(spotID) ? "Remove bookmark" : "Bookmark this spot"
                ) {
                    Task { await toggleBookmark() }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func details(for spot: Spot) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(spot.name)
                    .font(SCFont.heading(28))
                    .foregroundStyle(SCColor.textPrimary)
                Spacer()
                Text(locationLine(for: spot))
                    .font(.system(size: 14))
                    .foregroundStyle(SCColor.textSecondary)
            }

            HStack(spacing: 8) {
                Badge(text: spot.spotType.rawValue)
                Badge.difficulty(spot.difficulty)
                if !spot.isPublic {
                    Badge(text: "Private")
                }
            }

            HStack(spacing: 8) {
                if spot.isSkateable {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(SCColor.background)
                        .frame(width: 20, height: 20)
                        .background(SCColor.success)
                        .clipShape(Circle())
                    Text("Confirmed skateable")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(SCColor.success)
                } else {
                    Image(systemName: "questionmark.circle")
                        .foregroundStyle(SCColor.textSecondary)
                    Text("Unconfirmed")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(SCColor.textSecondary)
                }
            }

            if let description = spot.description, !description.isEmpty {
                Text(description)
                    .font(.system(size: 15))
                    .lineSpacing(4)
                    .foregroundStyle(SCColor.textBody)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !spot.features.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Features").scSectionLabel()
                    FlowChips(spacing: 8) {
                        ForEach(spot.features, id: \.self) { feature in
                            Text(feature.rawValue.uppercased())
                                .font(SCFont.headingFixed(11))
                                .foregroundStyle(SCColor.textPrimary)
                                .padding(.horizontal, 12)
                                .frame(height: 32)
                                .overlay(Capsule().stroke(SCColor.border, lineWidth: 1.5))
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Bust rate · from [N] logs").scSectionLabel()
                HStack(spacing: 8) {
                    SCStatTile(value: "[X]%", label: "Overall")
                    SCStatTile(value: "[X]%", label: "Weekdays")
                    SCStatTile(value: "[X]%", label: "Weekends")
                }
            }

            HStack(spacing: 10) {
                StarRating(rating: spot.rating)
                Text("\(spot.rating).0 avg")
                    .font(SCFont.headingFixed(14))
                    .foregroundStyle(SCColor.textPrimary)
            }

            // Not on the canvas's SpotDetail artboard: the way into booking a
            // filmer for this spot, with the spot already filled in.
            Button {
                showsFilmBooking = true
            } label: {
                SCIconDetailRow(
                    systemImage: "video.badge.plus",
                    title: "Request a filmer here",
                    subtitle: "Background-checked filmers near \(spot.name)"
                ) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(SCColor.accent)
                }
                .padding(12)
                .scCard(cornerRadius: SCRadius.cardSmall)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, SCMetric.screenPadding)
        .padding(.top, 24)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SCColor.background)
        .clipShape(
            UnevenRoundedRectangle(
                cornerRadii: .init(topLeading: SCRadius.sheet, topTrailing: SCRadius.sheet)
            )
        )
        .overlay(alignment: .top) { SCColor.border.frame(height: 1) }
        .offset(y: -26)
    }

    private func actionBar(for spot: Spot) -> some View {
        SCFooterBar {
            Button("Directions") { openDirections(to: spot) }
                .buttonStyle(.scPrimary(fontSize: 14))

            Button("Log session") { showBustLog = true }
                .buttonStyle(.scSecondary(fontSize: 14))
                .frame(width: 104)

            Button("Reviews") {}
                .buttonStyle(.scSecondary(fontSize: 14))
                .frame(width: 92)
        }
    }

    private func locationLine(for spot: Spot) -> String {
        if let distance = spot.distanceMeters {
            let miles = String(format: "%.1f", distance / 1609.34)
            return spot.city.isEmpty ? "\(miles) mi" : "\(miles) mi · \(spot.city)"
        }
        return spot.city
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
