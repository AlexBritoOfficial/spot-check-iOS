import Foundation
import Observation
import os
import Supabase

private let presenceLog = Logger(subsystem: "com.spotcheck.ios", category: "presence")

/// "Skating now" via Realtime Presence, deliberately NOT a persisted DB
/// column. A column would need a client heartbeat plus a server-side
/// expiry job, and the single most visible failure mode -- a stale green
/// dot after the app backgrounds or crashes -- is exactly what Presence
/// avoids: its state dies with the socket automatically. It also never
/// persists live location at rest. One channel per city bounds fan-out
/// (a single global channel would broadcast every skater's state to
/// every user).
@MainActor
@Observable
final class PresenceService {
    private(set) var presenceByUserID: [UUID: SkatingPresence] = [:]

    private let client: SupabaseClient
    private var channel: RealtimeChannelV2?
    private var listenTask: Task<Void, Never>?

    init(client: SupabaseClient = SupabaseClientProvider.shared) {
        self.client = client
    }

    func isOnline(_ userID: UUID) -> Bool {
        presenceByUserID[userID] != nil
    }

    func presence(for userID: UUID) -> SkatingPresence? {
        presenceByUserID[userID]
    }

    func join(city: String, me: SkatingPresence) {
        detachCurrentChannel()

        let slug = city.trimmingCharacters(in: .whitespaces).lowercased().replacingOccurrences(of: " ", with: "-")
        let ch = client.channel("presence:city:\(slug.isEmpty ? "unknown" : slug)")
        channel = ch

        listenTask = Task { [weak self] in
            guard let self else { return }
            // Register the presence callback (via presenceChange()) before
            // subscribe() -- the SDK silently refuses to attach one after
            // a channel is already subscribed.
            let stream = ch.presenceChange()
            await ch.subscribe()
            do {
                try await ch.track(me)
            } catch {
                presenceLog.error("track() failed: \(String(describing: error), privacy: .public)")
            }
            for await action in stream {
                self.apply(action)
            }
        }
    }

    func leave() async {
        listenTask?.cancel()
        listenTask = nil
        if let channel {
            await channel.untrack()
            await client.removeChannel(channel)
        }
        channel = nil
        presenceByUserID = [:]
    }

    private func detachCurrentChannel() {
        listenTask?.cancel()
        listenTask = nil
        if let channelToRemove = channel {
            Task { await self.client.removeChannel(channelToRemove) }
        }
        channel = nil
        presenceByUserID = [:]
    }

    private func apply(_ action: any PresenceAction) {
        if let joined = try? action.decodeJoins(as: SkatingPresence.self) {
            for presence in joined {
                presenceByUserID[presence.userID] = presence
            }
        }
        if let left = try? action.decodeLeaves(as: SkatingPresence.self) {
            for presence in left {
                presenceByUserID.removeValue(forKey: presence.userID)
            }
        }
    }
}
