import SwiftUI

/// Client-side filtering, matching the web app's FilterBar/ChipGroup --
/// never hits the server, just narrows what's already been fetched.
struct FilterChipsBar: View {
    @Binding var activeTypes: Set<SpotType>
    @Binding var activeFeatures: Set<Feature>

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SpotType.allCases, id: \.self) { type in
                    Chip(label: type.rawValue, isActive: activeTypes.contains(type)) {
                        toggle(type, in: &activeTypes)
                    }
                }
                Rectangle().fill(SCColor.border).frame(width: 1, height: 20)
                ForEach(Feature.allCases, id: \.self) { feature in
                    Chip(label: feature.rawValue, isActive: activeFeatures.contains(feature)) {
                        toggle(feature, in: &activeFeatures)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func toggle<T: Hashable>(_ value: T, in set: inout Set<T>) {
        if set.contains(value) {
            set.remove(value)
        } else {
            set.insert(value)
        }
    }
}

#Preview {
    FilterChipsBar(activeTypes: .constant(Set(SpotType.allCases)), activeFeatures: .constant(Set(Feature.allCases)))
        .padding(.vertical)
        .background(SCColor.background)
}
