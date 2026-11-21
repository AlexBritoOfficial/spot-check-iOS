-- spots_nearby: the PostGIS ST_DWithin/ST_Distance query, as a security
-- invoker RPC. PostgREST can't express ST_DWithin through normal filter
-- syntax and would return the geography column as a raw EWKB blob, so
-- this is the one place that logic lives. security invoker (the
-- default) means RLS on spots is applied *inside* the function, so
-- another user's private spots are filtered out automatically -- the
-- function needs no auth logic of its own. Radius is clamped to 100km,
-- the same MAX_RADIUS_METERS cap the web app enforces in its Zod schema.

create or replace function public.spots_nearby(
  p_lat           double precision,
  p_lng           double precision,
  p_radius_meters double precision default 8000,
  p_limit         integer          default 200
)
returns table (
  id              uuid,
  owner_id        uuid,
  name            text,
  city            text,
  spot_type       public.spot_type,
  description     text,
  features        public.feature[],
  difficulty      public.difficulty,
  is_skateable    boolean,
  is_public       boolean,
  rating          integer,
  lat             double precision,
  lng             double precision,
  photo           text,
  status          public.spot_status,
  created_at      timestamptz,
  distance_meters double precision
)
language sql
stable
security invoker
set search_path = public, extensions
as $$
  with origin as (
    select st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography as g
  )
  select s.id, s.owner_id, s.name, s.city, s.spot_type, s.description, s.features,
         s.difficulty, s.is_skateable, s.is_public, s.rating, s.lat, s.lng, s.photo,
         s.status, s.created_at,
         st_distance(s.lat_lng, o.g) as distance_meters
  from public.spots s, origin o
  where st_dwithin(s.lat_lng, o.g, least(greatest(p_radius_meters, 1), 100000))
  order by distance_meters asc
  limit least(greatest(p_limit, 1), 500);
$$;

revoke all on function public.spots_nearby(double precision, double precision, double precision, integer) from public;
grant execute on function public.spots_nearby(double precision, double precision, double precision, integer) to authenticated, anon;

-- my_conversations: one round trip for the whole Messages/Chats list,
-- including the per-conversation unread count (messages from the other
-- participant newer than my own last_read_at).
create or replace function public.my_conversations()
returns table (
  conversation_id              uuid,
  other_user_id                uuid,
  other_username                text,
  other_avatar_url              text,
  last_message_body             text,
  last_message_shared_spot_id   uuid,
  last_message_shared_spot_name text,
  last_message_at               timestamptz,
  unread_count                   integer
)
language sql
stable
security invoker
set search_path = public
as $$
  select c.id, p.id, p.username, p.avatar_url,
         m.body, m.shared_spot_id, sp.name,
         c.last_message_at,
         (select count(*) from public.messages m2
           where m2.conversation_id = c.id
             and m2.sender_id <> auth.uid()
             and m2.created_at > coalesce(me.last_read_at, '-infinity'::timestamptz))::int
  from public.conversations c
  join public.conversation_participants me
    on me.conversation_id = c.id and me.user_id = auth.uid()
  join public.conversation_participants other
    on other.conversation_id = c.id and other.user_id <> auth.uid()
  join public.profiles p on p.id = other.user_id
  left join lateral (
    select m.* from public.messages m
    where m.conversation_id = c.id order by m.created_at desc limit 1
  ) m on true
  left join public.spots sp on sp.id = m.shared_spot_id
  order by c.last_message_at desc;
$$;

-- start_conversation: find-or-create a 1:1 thread. security definer
-- because inserting the *other* participant is not something any
-- sane client-side policy should allow directly.
create or replace function public.start_conversation(p_other_user_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_me  uuid := auth.uid();
  v_key text;
  v_id  uuid;
begin
  if v_me is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;
  if v_me = p_other_user_id then
    raise exception 'cannot message yourself' using errcode = '22023';
  end if;
  if not exists (select 1 from public.profiles p where p.id = p_other_user_id) then
    raise exception 'no such user' using errcode = '23503';
  end if;

  v_key := least(v_me::text, p_other_user_id::text) || ':' || greatest(v_me::text, p_other_user_id::text);

  select c.id into v_id from public.conversations c where c.dm_key = v_key;
  if v_id is not null then
    return v_id;
  end if;

  insert into public.conversations (created_by, dm_key) values (v_me, v_key)
  on conflict (dm_key) do nothing
  returning id into v_id;

  if v_id is null then
    -- lost the race to a concurrent insert of the same dm_key
    select c.id into v_id from public.conversations c where c.dm_key = v_key;
  else
    insert into public.conversation_participants (conversation_id, user_id)
    values (v_id, v_me), (v_id, p_other_user_id);
  end if;

  return v_id;
end;
$$;

create or replace function public.mark_conversation_read(p_conversation_id uuid)
returns void
language sql
security invoker
set search_path = public
as $$
  update public.conversation_participants
     set last_read_at = now()
   where conversation_id = p_conversation_id and user_id = auth.uid();
$$;

grant execute on function public.my_conversations() to authenticated;
grant execute on function public.start_conversation(uuid) to authenticated;
grant execute on function public.mark_conversation_read(uuid) to authenticated;
