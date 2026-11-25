import Foundation
import Observation
import Supabase

enum AuthState: Equatable {
    case loading
    case signedOut
    case signedIn(userID: UUID)
}

/// Session state machine driving RootView. `authStateChanges` always
/// emits `.initialSession` as soon as it's subscribed to, so `state`
/// moves off `.loading` quickly even on cold start -- no separate
/// "check for an existing session" step needed.
@MainActor
@Observable
final class AuthManager {
    private(set) var state: AuthState = .loading
    private(set) var currentProfile: Profile?
    /// Only capabilities at status `.active`. Everything that gates on a
    /// capability checks membership here, so a paused filmer is excluded by
    /// construction rather than by each call site remembering to check.
    private(set) var currentCapabilities: Set<Capability> = []
    /// The user's Stripe Identity result, nil until they start one.
    private(set) var identityVerification: IdentityVerification?
    private(set) var lastError: String?

    private let client: SupabaseClient
    private let profiles: ProfilesRepository
    private let capabilities: CapabilitiesRepository
    private let identity: IdentityVerificationRepository

    // No deinit/cancellation: this is a single, app-lifetime root object
    // (held by SpotCheckApp's @State), so the listener task's lifetime is
    // the process's lifetime. A @MainActor property can't be touched
    // from deinit (nonisolated) under strict concurrency anyway.
    init(client: SupabaseClient = SupabaseClientProvider.shared) {
        self.client = client
        self.profiles = ProfilesRepository(client: client)
        self.capabilities = CapabilitiesRepository(client: client)
        self.identity = IdentityVerificationRepository(client: client)
        Task { [weak self] in
            guard let self else { return }
            await self.observeAuthState()
        }
    }

    private func observeAuthState() async {
        for await (event, session) in client.auth.authStateChanges {
            switch event {
            case .initialSession, .signedIn, .tokenRefreshed, .userUpdated:
                if let session {
                    state = .signedIn(userID: session.user.id)
                    await refreshProfile()
                } else {
                    state = .signedOut
                    currentProfile = nil
                    currentCapabilities = []
                    identityVerification = nil
                }
            case .signedOut, .userDeleted:
                state = .signedOut
                currentProfile = nil
                currentCapabilities = []
                identityVerification = nil
            case .passwordRecovery, .mfaChallengeVerified:
                break
            }
        }
    }

    func signUp(email: String, password: String, username: String, homeCity: String) async {
        lastError = nil
        do {
            try await client.auth.signUp(
                email: email,
                password: password,
                data: [
                    "username": .string(username),
                    "home_city": .string(homeCity),
                ]
            )
        } catch {
            lastError = error.localizedDescription
        }
    }

    func signIn(email: String, password: String) async {
        lastError = nil
        do {
            try await client.auth.signIn(email: email, password: password)
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Drives ASWebAuthenticationSession internally via supabase-swift;
    /// the redirect URL comes from the client's global auth.redirectToURL
    /// (spotcheck://auth-callback), configured once in SupabaseClientProvider.
    func signInWithGoogle() async {
        lastError = nil
        do {
            try await client.auth.signInWithOAuth(provider: .google)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func signOut() async {
        lastError = nil
        do {
            try await client.auth.signOut()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func refreshProfile() async {
        guard case .signedIn(let userID) = state else { return }
        currentProfile = try? await profiles.profile(id: userID)

        // A failed fetch leaves capabilities empty rather than stale: the safe
        // direction is to show less, never to leave a revoked capability's
        // surfaces reachable because the network blipped.
        let rows = (try? await capabilities.capabilities(for: userID)) ?? []
        currentCapabilities = Set(rows.filter(\.isActive).map(\.capability))

        identityVerification = try? await identity.verification(for: userID)
    }

    /// The backend's money-movement gate: verified *and* 18+.
    var isVerifiedAdult: Bool { identityVerification?.isVerifiedAdult == true }

    func has(_ capability: Capability) -> Bool {
        currentCapabilities.contains(capability)
    }
}
