-- spots: lat/lng are plain columns; lat_lng is a generated PostGIS
-- geography column kept in sync automatically on every insert/update, so
-- there's no two-step "insert row, then raw-SQL UPDATE the geometry"
-- dance like the web app's Prisma code needs (Prisma can't write to an
-- Unsupported("geography(...)") column directly).

create table public.spots (
  id           uuid primary key default gen_random_uuid(),
  owner_id     uuid references auth.users(id) on delete set null,
  name         text not null check (length(trim(name)) > 0),
  city         text not null default '',
  spot_type    public.spot_type not null,
  description  text,
  features     public.feature[] not null default '{}',
  difficulty   public.difficulty not null,
  is_skateable boolean not null default true,
  is_public    boolean not null default true,
  rating       integer not null default 0 check (rating between 0 and 5),
  lat          double precision not null check (lat between -90 and 90),
  lng          double precision not null check (lng between -180 and 180),
  lat_lng      extensions.geography(Point, 4326)
                 generated always as (
                   extensions.st_setsrid(extensions.st_makepoint(lng, lat), 4326)::extensions.geography
                 ) stored,
  photo        text,                 -- object path inside the `spot-photos` bucket, not a URL
  status       public.spot_status not null default 'active',
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index spots_lat_lng_gix   on public.spots using gist (lat_lng);
create index spots_owner_id_idx  on public.spots (owner_id);
create index spots_features_gix  on public.spots using gin (features);

create trigger spots_touch_updated_at
  before update on public.spots
  for each row execute function public.touch_updated_at();
