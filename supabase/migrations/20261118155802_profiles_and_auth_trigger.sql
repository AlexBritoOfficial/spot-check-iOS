-- profiles: extends auth.users. username + home_city are collected at
-- signup and required; everything else is nullable because a Google
-- OAuth signup only supplies email + name/picture, not stance/age/etc.

create table public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  username      text not null unique
                  check (username ~ '^[a-zA-Z0-9_]{3,30}$'),
  home_city     text not null default '',
  first_name    text,
  last_name     text,
  stance        text,
  discipline    text,
  avatar_url    text,            -- storage path in `avatars`, or an OAuth picture URL
  age           integer check (age is null or age between 13 and 120),
  years_skating integer check (years_skating is null or years_skating >= 0),
  filmer        boolean not null default false,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index profiles_home_city_idx on public.profiles (lower(home_city));

-- Shared "touch updated_at" trigger function, reused by profiles and spots.
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger profiles_touch_updated_at
  before update on public.profiles
  for each row execute function public.touch_updated_at();

-- handle_new_user: populates profiles on every auth.users insert.
--   1. username comes from signup metadata, else derived from the email
--      local-part (Google OAuth sends no username).
--   2. Collisions are resolved by appending a numeric suffix instead of
--      raising -- raising here makes signUp return an opaque 500 and
--      rolls back the auth.users row.
--   3. `on conflict do nothing` makes retries idempotent and never blocks
--      a signup on a trigger race.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  candidate text;
  suffix    int := 0;
begin
  candidate := nullif(trim(new.raw_user_meta_data ->> 'username'), '');
  if candidate is null then
    candidate := regexp_replace(split_part(coalesce(new.email, 'skater'), '@', 1),
                                 '[^a-zA-Z0-9_]', '', 'g');
  end if;
  candidate := left(coalesce(nullif(candidate, ''), 'skater'), 24);
  if length(candidate) < 3 then
    candidate := candidate || 'skater';
  end if;

  -- coalesce(..., '') matters: `text || NULL` is NULL in Postgres, so
  -- without it every suffix=0 attempt (nullif(0,0) = NULL) would try to
  -- insert a NULL username and fail the NOT NULL constraint.
  while exists (
    select 1 from public.profiles p
    where p.username = candidate || coalesce(nullif(suffix, 0)::text, '')
  ) loop
    suffix := suffix + 1;
  end loop;

  insert into public.profiles (id, username, home_city, first_name, last_name, avatar_url)
  values (
    new.id,
    candidate || coalesce(nullif(suffix, 0)::text, ''),
    coalesce(new.raw_user_meta_data ->> 'home_city', ''),
    new.raw_user_meta_data ->> 'first_name',
    new.raw_user_meta_data ->> 'last_name',
    coalesce(new.raw_user_meta_data ->> 'avatar_url', new.raw_user_meta_data ->> 'picture')
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
