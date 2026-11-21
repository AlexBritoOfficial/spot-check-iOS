# Domain glossary

Mirrors the web app's `CONTEXT.md`, updated for what's actually implemented
here. See the plan at the time of writing for the full rationale:
`~/.claude/plans/this-is-the-design-tingly-phoenix.md`.

**Spot** — a skate spot: name, city, type (park/street/diy), features,
difficulty, a lat/lng, visibility, and a status. Has a single `owner_id`
(nullable — ownerless spots exist only in seed data; the app itself
requires auth to create one).

**Owner** — the user who created a spot (`spots.owner_id`). Sole source
of authorship; separate from bookmarking.

**Bookmark** — a saved reference to a spot you do *not* own. Never
created for your own spots (enforced by RLS). "Your private spots" on
the Bookmarks screen is a live filter over spots you own with
`is_public = false`, not a stored bookmark row — this avoids staleness
if a spot's visibility changes later.

**Public / private spot** — `is_public` controls visibility to everyone
except the owner. A private spot still renders on the map for its
owner, in a distinct pin color; it's simply invisible (filtered by RLS,
not client-side) to everyone else. There is currently a two-color pin
scheme (default / owned-by-me); a third color for "owned by someone
else" is deliberately deferred, matching the web app's own documented
decision.

**Profile** — a user's public-facing info (`username`, `home_city`,
`first_name`/`last_name`, `stance`, `discipline`, `avatar_url`, `age`,
`years_skating`). `@handle` is always derived as `"@" + username`, never
stored. `filmer` is an informational flag only — there's no workflow
attached to it yet (see "Explicitly out of scope" below).

**Conversation / Message** — a 1:1 DM thread. `conversations.dm_key`
guarantees at most one thread per pair of users. A message can carry a
`shared_spot_id` instead of (or alongside) body text; sharing a private
spot is blocked at write time. Unread counts are computed from each
participant's own `last_read_at`.

**Sign in** — real email/password and Google OAuth via Supabase Auth
(unlike the web app, where sign-in/sign-up are still mock UI with
nothing persisted). Email confirmation is off for now — see README.

## Explicitly out of scope (this pass)

No schema, no screens wired for: **Booking** (lessons), **FilmBooking**
(paid filming/photo sessions), **FilmerQualify** / **ProApply** /
**ProProfile** (Pro application + background check), **ClipUpload** /
**ClipVault** (raw footage delivery), and any payments/escrow. The
design canvas's "Verification" screen is specifically the Pro
background-check status screen, not an auth/OTP step — there is no
email/phone verification screen in this app's flow at all.
