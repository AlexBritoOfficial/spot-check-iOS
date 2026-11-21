# Spot Check (iOS)

Native SwiftUI companion to the `spot-check-web` web app, backed by
Supabase (Postgres + PostGIS, Auth, Storage, Realtime). See `CONTEXT.md`
for the domain glossary.

**Schema ownership has moved to `spot-check-backend`** — `supabase/` here is left in place for now (not yet deleted, a deliberate follow-up decision) but is no longer the source of truth. Run `supabase start`/`db reset` from either repo; both resolve to the same local stack (see "Environments" below).

## Environments

Four build configs, four Xcode schemes:

| Scheme | Config | Bundle ID | Points at |
|---|---|---|---|
| `SpotCheck` | Debug | `com.spotcheck.ios` | local `supabase start` stack |
| `SpotCheck-QA` | QA | `com.spotcheck.ios.qa` | `spot-check-test` (hosted, not yet provisioned) |
| `SpotCheck-Staging` | Staging | `com.spotcheck.ios.staging` | `spot-check-staging` (hosted, not yet provisioned) |
| `SpotCheck-Release` | Release | `com.spotcheck.ios` | `spot-check-production` (hosted, not yet provisioned) |

Debug and Release intentionally share a bundle ID (matching the app's
pre-existing identity); only QA/Staging get suffixes, so all three
non-Release builds can coexist on one device/simulator.

Each config's secrets live in `Config/Secrets.xcconfig` /
`Secrets.QA.xcconfig` / `Secrets.Staging.xcconfig` /
`Secrets.Production.xcconfig` — all gitignored. `Secrets.xcconfig`
(Debug) already exists, pointed at the local stack, so a fresh
`supabase start` + an Xcode build on the `SpotCheck` scheme works with no
extra setup. The other three don't exist yet — QA/Staging/Release build
successfully without them (their `#include?` is optional), but
launching crashes with a clear message until you copy the matching
`Secrets.*.example.xcconfig` template and fill in a real hosted
project's values.

After editing `project.yml`, regenerate with `xcodegen generate` — never
hand-edit `SpotCheck.xcodeproj`.

## Backend (Supabase)

Prereqs: Docker running, Supabase CLI (`brew install supabase/tap/supabase`).

```sh
supabase start      # boots the local stack (Postgres, Auth, Storage, Realtime, Studio)
supabase db reset   # (re)applies every migration in supabase/migrations/ + supabase/seed.sql
```

Studio UI: http://127.0.0.1:54323. API: http://127.0.0.1:54321.

To point a config at its hosted project instead of the local stack:

1. `supabase link --project-ref <ref>` (run from `spot-check-backend`)
2. `supabase db push`
3. Copy that environment's `Config/Secrets.*.example.xcconfig` →
   `Config/Secrets.*.xcconfig`, fill in the hosted project's
   `SUPABASE_HOST` / `SUPABASE_ANON_KEY`, scheme `https`.

## Still open before this is production-ready

- Email confirmation is off (`supabase/config.toml`) — re-enable with custom SMTP before any public release.
- Google OAuth client hasn't been created yet (needs a Google Cloud Console project + OAuth client, wired into the Supabase dashboard's Auth providers).
- Booking, Pro/filmer qualification, clip vault, and payments/escrow have no schema yet — out of scope for this pass, see the design canvas for the screens that will need them.
