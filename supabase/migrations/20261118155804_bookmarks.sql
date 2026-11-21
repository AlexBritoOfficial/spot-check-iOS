-- bookmarks: a bookmark is only ever for a spot you do NOT own (see
-- CONTEXT.md / grill-sign-in-account.md in the web app). "Your private
-- spots" on the Bookmarks screen is a live filter over spots you own
-- with is_public = false, not a stored bookmark row -- that avoids
-- staleness if visibility ever flips. The unique pair makes the
-- bookmark toggle idempotent (upsert on, delete off).

create table public.bookmarks (
  id       uuid primary key default gen_random_uuid(),
  user_id  uuid not null references auth.users(id) on delete cascade,
  spot_id  uuid not null references public.spots(id) on delete cascade,
  saved_at timestamptz not null default now(),
  unique (user_id, spot_id)
);

create index bookmarks_user_id_idx on public.bookmarks (user_id, saved_at desc);

-- Used by RLS to block "bookmark your own spot" without an in-policy
-- subquery that would otherwise need its own RLS carve-out.
create or replace function public.spot_owner_id(p_spot_id uuid)
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select s.owner_id from public.spots s where s.id = p_spot_id;
$$;
