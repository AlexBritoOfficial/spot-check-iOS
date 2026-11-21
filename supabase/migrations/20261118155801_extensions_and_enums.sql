-- Spot Check: extensions and shared enums.
-- Enum values are byte-identical to the web app's Prisma enums so future
-- web-app rows map 1:1 onto this schema. No "bowl" feature: it only ever
-- appeared as a stale filter-chip label in an old design doc, never in a
-- real enum anywhere.

create extension if not exists postgis with schema extensions;

create type public.spot_type as enum ('park', 'street', 'diy');

create type public.feature as enum ('ledge', 'rail', 'plaza', 'stairs', 'skatepark');

create type public.difficulty as enum ('beginner', 'intermediate', 'advanced', 'pro');

create type public.spot_status as enum ('active', 'pending', 'closed');
