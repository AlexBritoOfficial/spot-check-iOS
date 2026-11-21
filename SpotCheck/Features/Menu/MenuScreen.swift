import SwiftUI

/// Bookmarks and Messages already have their own tabs, so this doesn't
/// repeat them -- just the profile header, "My profile," and sign out.
/// Notifications/Settings and "Earn with Spot Check" from the design
/// canvas have no backend behind them in this pass, so they're left out
/// rather than added as dead buttons.
struct MenuScreen: View {
    @Environment(AuthManager.self) private var authManager
    @State private var showProfile = false

    var body: some View {
        NavigationStack {
            List {
                if let profile = authManager.currentProfile {
                    Section {
                        HStack(spacing: 14) {
                            Circle()
                                .fill(Color(.tertiarySystemFill))
                                .frame(width: 56, height: 56)
                                .overlay(Text(profile.username.prefix(1).uppercased()).font(.title2.bold()))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.username).font(.headline)
                                Text(profile.handle).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }

                Section {
                    Button {
                        showProfile = true
                    } label: {
                        Label("My Profile", systemImage: "person.circle")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        Task { await authManager.signOut() }
                    } label: {
                        Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Menu")
            .navigationDestination(isPresented: $showProfile) {
                if let id = authManager.currentProfile?.id {
                    SkaterProfileScreen(userID: id)
                }
            }
        }
    }
}
