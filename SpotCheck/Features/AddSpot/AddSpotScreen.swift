import CoreLocation
import PhotosUI
import SwiftUI

struct AddSpotScreen: View {
    let initialCoordinate: CLLocationCoordinate2D

    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var authManager
    @Environment(SpotsStore.self) private var spotsStore

    @State private var name = ""
    @State private var spotType: SpotType = .street
    @State private var selectedFeatures: Set<Feature> = []
    @State private var difficulty: Difficulty = .intermediate
    @State private var isPublic = true
    @State private var description = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && !isSubmitting }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Text("ADD A NEW SPOT")
                        .font(SCFont.headingFixed(18))
                        .foregroundStyle(SCColor.textPrimary)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(SCColor.textPrimary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .overlay(Rectangle().fill(SCColor.border).frame(height: 1), alignment: .bottom)

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        pinPreview

                        photoPicker

                        SCTextField(label: "Spot Name", placeholder: "e.g. Riverside Bowl", text: $name)

                        chipSection(title: "Spot Type") {
                            ForEach(SpotType.allCases, id: \.self) { type in
                                Chip(label: type.rawValue, isActive: spotType == type) { spotType = type }
                            }
                        }

                        chipSection(title: "Spot Features") {
                            ForEach(Feature.allCases, id: \.self) { feature in
                                Chip(label: feature.rawValue, isActive: selectedFeatures.contains(feature)) {
                                    toggle(feature)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("DIFFICULTY").scFieldLabel()
                            Menu {
                                ForEach(Difficulty.allCases, id: \.self) { level in
                                    Button(level.rawValue.capitalized) { difficulty = level }
                                }
                            } label: {
                                HStack {
                                    Text(difficulty.rawValue.capitalized)
                                        .font(SCFont.headingFixed(15))
                                        .foregroundStyle(SCColor.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundStyle(SCColor.textSecondary)
                                }
                                .scFieldContainerChrome()
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("VISIBILITY").scFieldLabel()
                            HStack(spacing: 8) {
                                Chip(label: "Public", isActive: isPublic) { isPublic = true }
                                Chip(label: "Private", isActive: !isPublic) { isPublic = false }
                            }
                            Text("Private spots stay on your map only.")
                                .font(.system(size: 13))
                                .foregroundStyle(SCColor.textSecondary)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("DESCRIPTION").scFieldLabel()
                            ZStack(alignment: .topLeading) {
                                if description.isEmpty {
                                    Text("What makes this spot worth skating?")
                                        .foregroundStyle(SCColor.textSecondary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .allowsHitTesting(false)
                                }
                                TextEditor(text: $description)
                                    .scrollContentBackground(.hidden)
                                    .foregroundStyle(SCColor.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .frame(minHeight: 90)
                            }
                            .background(SCColor.inputFill)
                            .clipShape(RoundedRectangle(cornerRadius: SCRadius.control))
                        }

                        if let errorMessage {
                            Text(errorMessage).font(.footnote).foregroundStyle(SCColor.danger)
                        }
                    }
                    .padding(20)
                }

                HStack(spacing: 10) {
                    Button {
                        Task { await save() }
                    } label: {
                        Group {
                            if isSubmitting {
                                ProgressView().tint(SCColor.background)
                            } else {
                                Text("Save Spot").font(SCFont.buttonLabel)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: SCMetric.controlHeight)
                    .background(canSave ? SCColor.accent : SCColor.accent.opacity(0.4))
                    .foregroundStyle(SCColor.background)
                    .clipShape(RoundedRectangle(cornerRadius: SCRadius.control))
                    .disabled(!canSave)

                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(SCFont.buttonLabel)
                            .foregroundStyle(SCColor.textPrimary)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(height: SCMetric.controlHeight)
                    .overlay(RoundedRectangle(cornerRadius: SCRadius.control).stroke(SCColor.border, lineWidth: 1.5))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .overlay(Rectangle().fill(SCColor.border).frame(height: 1), alignment: .top)
            }
            .background(SCColor.background)
            .toolbar(.hidden)
        }
    }

    private var pinPreview: some View {
        ZStack {
            SCColor.backgroundDeep
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(SCColor.background, SCColor.accent)
        }
        .frame(height: 110)
        .clipShape(RoundedRectangle(cornerRadius: SCRadius.card))
        .overlay(RoundedRectangle(cornerRadius: SCRadius.card).stroke(SCColor.border, lineWidth: 1))
    }

    private var photoPicker: some View {
        let currentPhotoData = photoData
        return PhotosPicker(selection: $photoItem, matching: .images) {
            Group {
                if let currentPhotoData, let uiImage = UIImage(data: currentPhotoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    VStack(spacing: 6) {
                        Text("+ ADD PHOTO").font(SCFont.headingFixed(14)).foregroundStyle(SCColor.textPrimary)
                        Text("Take a photo or choose from library")
                            .font(.system(size: 13))
                            .foregroundStyle(SCColor.textSecondary)
                    }
                }
            }
            .frame(height: 130)
            .frame(maxWidth: .infinity)
        }
        .background(SCColor.inputFill)
        .clipShape(RoundedRectangle(cornerRadius: SCRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: SCRadius.card)
                .strokeBorder(SCColor.textSecondary, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
        )
        .onChange(of: photoItem) { _, newItem in
            Task { @MainActor in
                photoData = try? await newItem?.loadTransferable(type: Data.self)
            }
        }
    }

    private func chipSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased()).scFieldLabel()
            FlowChips { content() }
        }
    }

    private func toggle(_ feature: Feature) {
        if selectedFeatures.contains(feature) {
            selectedFeatures.remove(feature)
        } else {
            selectedFeatures.insert(feature)
        }
    }

    private func save() async {
        guard let ownerID = authManager.currentProfile?.id else {
            errorMessage = "You must be signed in to add a spot."
            return
        }
        isSubmitting = true
        defer { isSubmitting = false }

        // Generated here (not left to the DB default) so a photo upload
        // can reference this spot's id before the row exists.
        let spotID = UUID()

        do {
            var photoPath: String?
            if let photoData {
                photoPath = try await SpotPhotoStorage.upload(ownerID: ownerID, spotID: spotID, imageData: photoData)
            }

            let newSpot = NewSpot(
                id: spotID,
                ownerID: ownerID,
                name: name,
                city: "",
                spotType: spotType,
                description: description.isEmpty ? nil : description,
                features: Array(selectedFeatures),
                difficulty: difficulty,
                isSkateable: true,
                isPublic: isPublic,
                lat: initialCoordinate.latitude,
                lng: initialCoordinate.longitude,
                photo: photoPath
            )
            try await spotsStore.create(newSpot)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
