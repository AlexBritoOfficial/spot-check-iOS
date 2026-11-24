import SwiftUI

enum MainTab: CaseIterable {
    case map, feed, discover, chat, profile

    var label: String {
        switch self {
        case .map: "MAP"
        case .feed: "FEED"
        case .discover: "DISCOVER"
        case .chat: "CHAT"
        case .profile: "PROFILE"
        }
    }

    var systemImage: String {
        switch self {
        case .map: "map"
        case .feed: "play.rectangle"
        case .discover: "safari"
        case .chat: "bubble.left"
        case .profile: "person.crop.circle"
        }
    }

    /// Always four tabs, two either side of the raised post action. Filmer mode
    /// swaps FEED for DISCOVER, which is exactly what
    /// `Features/Filming/DiscoverScreen` defers: "the canvas draws a filmer-mode
    /// bar with DISCOVER replacing FEED".
    ///
    /// Industry deliberately gets the skater bar -- the canvas gives industry
    /// accounts no bottom-bar destination of their own, only drawer rows.
    static func tabs(for mode: AppMode) -> [MainTab] {
        switch mode {
        case .skater, .industry: [.map, .feed, .chat, .profile]
        case .filmer: [.map, .discover, .chat, .profile]
        }
    }
}

/// The canvas's own bottom bar: four labeled destinations with the
/// post-a-clip action raised in the middle. Replaces the system tab bar
/// (which can't host the overhanging center button, and whose chrome
/// the canvas doesn't use anywhere).
struct SCBottomNavBar: View {
    @Binding var selection: MainTab
    /// Always four, supplied by `MainTab.tabs(for:)` so the bar doesn't need to
    /// know about modes.
    var tabs: [MainTab] = MainTab.tabs(for: .skater)
    var chatBadge: Int?
    var onPost: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(tabs.prefix(2)), id: \.self) { item($0) }
            postButton
            ForEach(Array(tabs.dropFirst(2)), id: \.self) { tab in
                item(tab, badge: tab == .chat ? chatBadge : nil)
            }
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
