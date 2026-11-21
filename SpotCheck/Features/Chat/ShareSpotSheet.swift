import SwiftUI

/// Only public spots are offered -- sharing a private one is rejected
/// server-side anyway (see the messages insert RLS policy), so this
/// list matches what would actually be allowed to send.
struct ShareSpotSheet: View {
    let spots: [Spot]
    let onSelect: (Spot) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if spots.isEmpty {
                    ContentUnavailableView(
                        "No spots to share",
                        systemImage: "mappin.slash",
                        description: Text("Spots you've seen on the map will show up here.")
                    )
                } else {
                    List(spots) { spot in
                        Button {
                            onSelect(spot)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(spot.name).font(.headline).foregroundStyle(.primary)
                                Text(spot.city).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Share a spot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
