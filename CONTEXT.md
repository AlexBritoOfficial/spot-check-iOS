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

## The marketplace screens: drawn, not wired

The business model expanded, and the design canvas ("Spot Check
Mobile", 36 artboards) is now the source of truth for both iOS and
Android. Every artboard has a SwiftUI screen in `Features/`, but only
the ones above are backed by schema and repositories. These are
**visuals only** — static sample content, local view state, empty
button actions — pending per-feature planning:

**Filmers** — a skater books a background-checked filmer for a session,
the filmer delivers raw clips, money is held until both confirm.
`FilmerOnboarding/` (apply, qualifications, background check, public
filmer profile), `Filming/` (booking, the filmer's request inbox, clip
upload, the skater's clip vault), `FilmerTools/` (rates, earnings,
two-way rating, the three-strike pause).

**Clips & visibility** — `Clips/` (feed, posting a clip, the monthly
challenge) and `Portfolio/` (the signed-in skater's own portfolio and
sponsorship ladder, profile insights).

**Industry** — `Opportunities/` (offers a skater receives, scouting,
sending an offer) for verified shop/brand accounts.

**Trust & safety** — `Trust/` (18+ ID check, bust logging, paid pro
Q&A, report and block).

Terms worth knowing: a **bust** is getting kicked out of a spot by
security or police, and bust logs feed a spot's bust rate. A **make**
vs. a **bail** is a landed trick vs. a failed one, which is how raw
clips get tagged. The canvas's "Verification" screen is the filmer
background-check status, not an auth/OTP step; "IDVerify" is the
separate 18+ identity check.

Still absent entirely: any schema for the above, payments/escrow, and
**Booking** (lessons, which the canvas doesn't cover).
