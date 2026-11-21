-- Two buckets. avatars is public (low sensitivity, benefits from plain
-- cacheable URLs in AsyncImage). spot-photos is private with signed
-- URLs only -- a bucket's public flag is all-or-nothing, so a
-- public/private path *prefix* inside one public bucket would give
-- zero real protection, and splitting into two buckets by visibility
-- would mean every is_public toggle has to move the object between
-- buckets (a copy+delete that can half-fail and orphan a photo). One
-- private bucket with visibility checked at read time avoids both.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 5242880,
        array['image/jpeg', 'image/png', 'image/heic', 'image/webp'])
on conflict (id) do nothing;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('spot-photos', 'spot-photos', false, 10485760,
        array['image/jpeg', 'image/png', 'image/heic', 'image/webp'])
on conflict (id) do nothing;

-- avatars: world-readable, owner-writable under their own {user_id}/ prefix.
create policy "avatars are publicly readable"
  on storage.objects for select to public using (bucket_id = 'avatars');

create policy "users write their own avatar"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "users update their own avatar"
  on storage.objects for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "users delete their own avatar"
  on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

-- spot-photos: path convention is {owner_id}/{spot_id}/{uuid}.jpg.
-- Reads are gated by the referenced spot's own visibility rule, so a
-- photo is readable iff the spot it belongs to is readable.
create or replace function public.can_read_spot_photo(p_object_name text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.spots s
    where s.id = nullif((storage.foldername(p_object_name))[2], '')::uuid
      and (s.is_public or s.owner_id = auth.uid())
  );
$$;

create policy "spot photos follow spot visibility"
  on storage.objects for select to authenticated, anon
  using (bucket_id = 'spot-photos' and public.can_read_spot_photo(name));

-- Upload happens before the spot row exists (the client pre-generates
-- the spot's uuid so AddSpot can upload the photo first, then insert
-- the spot referencing it) -- so the insert policy only checks the
-- owner-id path prefix, not spot visibility.
create policy "owners upload photos under their own prefix"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'spot-photos' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "owners update their own spot photos"
  on storage.objects for update to authenticated
  using (bucket_id = 'spot-photos' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "owners delete their own spot photos"
  on storage.objects for delete to authenticated
  using (bucket_id = 'spot-photos' and (storage.foldername(name))[1] = auth.uid()::text);
