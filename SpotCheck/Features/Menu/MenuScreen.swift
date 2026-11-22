import SwiftUI

/// The slide-out drawer from the canvas's `Menu` artboard: a 320pt
/// panel with the profile header and the canvas's full row set.
///
/// The canvas draws unread badges on Opportunities and Messages. They're
/// left off here rather than hardcoded -- this is a live screen, and
/// nothing feeds those counts yet. `SCBottomNavBar`'s badge is plumbed
/// the same way.
struct MenuScreen: View {
    @Environment(AuthManager.self) private var authManager

    var onClose: () -> Void
    var onSelectProfile: () -> Void
    var onSelectMessages: () -> Void
    var onSelect: (MenuCoordinator.Destination) -> Void
    var onSignOut: () -> Void

    private let panelWidth: CGFloat = 320

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if let profile = authManager.currentProfile {
                profileRow(profile)
            }
            rows
            Spacer()
        }
        .frame(width: panelWidth)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(SCColor.background)
        .overlay(alignment: .trailing) {
            SCColor.border.frame(width: 1)
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack {
            Wordmark(size: 20)
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(SCColor.textPrimary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close menu")
        }
        .padding(.leading, 20)
        .padding(.trailing, 10)
        .padding(.top, 52)
        .padding(.bottom, 14)
        .overlay(alignment: .bottom) {
            SCColor.border.frame(height: 1)
        }
    }

    private func profileRow(_ profile: Profile) -> some View {
        HStack(spacing: 14) {
            Avatar(initial: profile.username, size: 56)
            VStack(alignment: .leading, spacing: 3) {
                Text(profile.username)
                    .font(SCFont.headingFixed(16))
                    .foregroundStyle(SCColor.textPrimary)
                Text(profile.handle)
                    .font(.system(size: 13))
                    .foregroundStyle(SCColor.textSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
    }

    private var rows: some View {
        VStack(spacing: 0) {
            row(title: "My profile", systemImage: "person", action: onSelectProfile)
            row(title: "Bookmarks", systemImage: "bookmark") { onSelect(.bookmarks) }
            row(title: "Opportunities", systemImage: "briefcase") { onSelect(.opportunities) }
            row(title: "Messages", systemImage: "bubble.left", action: onSelectMessages)
            row(
                title: "Earn with Spot Check",
                systemImage: "dollarsign.circle",
                tint: SCColor.accent
            ) { onSelect(.becomeFilmer) }
            row(title: "Filming requests", systemImage: "safari", tag: "Filmers") {
                onSelect(.filmingRequests)
            }
            row(title: "Scout skaters", systemImage: "magnifyingglass", tag: "Industry") {
                onSelect(.scoutSkaters)
            }
            row(title: "Notifications", systemImage: "bell") {}
            row(title: "Settings", systemImage: "gearshape") {}
            row(
                title: "Sign out",
                systemImage: "rectangle.portrait.and.arrow.right",
                tint: SCColor.danger,
                showsBottomDivider: true,
                action: onSignOut
            )
        }
        .padding(.horizontal, 20)
    }

    private func row(
        title: String,
        systemImage: String,
        tint: Color = SCColor.textPrimary,
        tag: String? = nil,
        showsBottomDivider: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 17))
                    .frame(width: 20)
                    .foregroundStyle(tint == SCColor.textPrimary ? SCColor.textSecondary : tint)
                Text(title)
                    .font(SCFont.headingFixed(15))
                    .foregroundStyle(tint)
                Spacer(minLength: 8)
                if let tag {
                    SCTag(
                        text: tag,
                        foreground: SCColor.textSecondary,
                        background: SCColor.border,
                        size: 9.5
                    )
                }
            }
            .frame(height: 56)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .top) {
            SCColor.border.frame(height: 1)
        }
        .overlay(alignment: .bottom) {
            if showsBottomDivider {
                SCColor.border.frame(height: 1)
            }
        }
    }
}

#Preview {
    ZStack(alignment: .leading) {
        Color.black.opacity(0.6).ignoresSafeArea()
        MenuScreen(
            onClose: {},
            onSelectProfile: {},
            onSelectMessages: {},
            onSelect: { _ in },
            onSignOut: {}
        )
    }
    .environment(AuthManager())
}
