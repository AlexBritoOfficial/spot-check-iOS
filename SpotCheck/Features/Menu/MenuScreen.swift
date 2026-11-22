import SwiftUI

/// The slide-out drawer opened by the hamburger button on each tab
/// (see `MenuCoordinator`) -- matches the design canvas's `Menu.dc.html`
/// panel-from-the-left layout, not a bottom tab.
///
/// Bookmarks and Messages already have their own tabs, so this doesn't
/// repeat them -- just the profile header, "My profile," and sign out.
/// Notifications/Settings and "Earn with Spot Check" from the design
/// canvas have no backend behind them in this pass, so they're left out
/// rather than added as dead buttons.
struct MenuScreen: View {
    @Environment(AuthManager.self) private var authManager

    var onClose: () -> Void
    var onSelectProfile: () -> Void

    private let panelWidth: CGFloat = 320

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if let profile = authManager.currentProfile {
                profileRow(profile)
            }
            VStack(spacing: 0) {
                row(title: "My Profile", systemImage: "person.circle", action: onSelectProfile)
                row(title: "Sign out", systemImage: "rectangle.portrait.and.arrow.right", isDestructive: true) {
                    Task { await authManager.signOut() }
                }
            }
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
            Wordmark(size: 18)
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(SCColor.textPrimary)
                    .frame(width: 44, height: 44)
            }
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
                Text(profile.username).font(SCFont.headingFixed(16)).foregroundStyle(SCColor.textPrimary)
                Text(profile.handle).font(.system(size: 13)).foregroundStyle(SCColor.textSecondary)
            }
        }
        .padding(20)
    }

    private func row(
        title: String,
        systemImage: String,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .frame(width: 20)
                    .foregroundStyle(isDestructive ? SCColor.danger : SCColor.textSecondary)
                Text(title)
                    .font(SCFont.headingFixed(15))
                    .foregroundStyle(isDestructive ? SCColor.danger : SCColor.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .frame(height: 56)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .top) {
            SCColor.border.frame(height: 1)
        }
    }
}

#Preview {
    ZStack(alignment: .leading) {
        Color.black.opacity(0.6).ignoresSafeArea()
        MenuScreen(onClose: {}, onSelectProfile: {})
    }
    .environment(AuthManager())
}
