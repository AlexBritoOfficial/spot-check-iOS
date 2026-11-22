import SwiftUI

enum MainTab: CaseIterable {
    case map, feed, chat, profile

    var label: String {
        switch self {
        case .map: "MAP"
        case .feed: "FEED"
        case .chat: "CHAT"
        case .profile: "PROFILE"
        }
    }

    var systemImage: String {
        switch self {
        case .map: "map"
        case .feed: "play.rectangle"
        case .chat: "bubble.left"
        case .profile: "person.crop.circle"
        }
    }
}

/// The canvas's own bottom bar: four labeled destinations with the
/// post-a-clip action raised in the middle. Replaces the system tab bar
/// (which can't host the overhanging center button, and whose chrome
/// the canvas doesn't use anywhere).
struct SCBottomNavBar: View {
    @Binding var selection: MainTab
    var chatBadge: Int?
    var onPost: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            item(.map)
            item(.feed)
            postButton
            item(.chat, badge: chatBadge)
            item(.profile)
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .frame(height: SCMetric.bottomNavHeight, alignment: .top)
        .background(SCColor.background)
        .overlay(alignment: .top) { SCColor.border.frame(height: 1) }
    }

    private func item(_ tab: MainTab, badge: Int? = nil) -> some View {
        let isActive = selection == tab
        return Button {
            selection = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 21, weight: .regular))
                    .overlay(alignment: .topTrailing) {
                        if let badge, badge > 0 {
                            Text("\(badge)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(SCColor.background)
                                .padding(.horizontal, 5)
                                .frame(minWidth: 18, minHeight: 18)
                                .background(SCColor.accent)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(SCColor.background, lineWidth: 2))
                                .offset(x: 11, y: -7)
                        }
                    }
                Text(tab.label)
                    .font(SCFont.tabLabel)
            }
            .foregroundStyle(isActive ? SCColor.accent : SCColor.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label.capitalized)
        .accessibilityAddTraits(isActive ? [.isSelected, .isButton] : .isButton)
    }

    private var postButton: some View {
        Button(action: onPost) {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(SCColor.background)
                .frame(width: 60, height: 60)
                .background(SCColor.accent)
                .clipShape(Circle())
                .overlay(Circle().stroke(SCColor.background, lineWidth: 4))
                .shadow(color: .black.opacity(0.45), radius: 9, y: 6)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .offset(y: -22)
        .accessibilityLabel("Post a clip")
    }
}

#Preview {
    @Previewable @State var selection = MainTab.map

    return VStack {
        Spacer()
        SCBottomNavBar(selection: $selection, chatBadge: 2) {}
    }
    .background(SCColor.backgroundDeep)
}
