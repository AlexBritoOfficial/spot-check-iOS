alter table public.profiles                  enable row level security;
alter table public.spots                     enable row level security;
alter table public.bookmarks                 enable row level security;
alter table public.conversations             enable row level security;
alter table public.conversation_participants enable row level security;
alter table public.messages                  enable row level security;

-- profiles: readable by any signed-in user (the Messages rail and
-- SkaterProfile need a directory to look people up in); writable only
-- by the owning user. No delete policy -- profiles die via the
-- auth.users cascade.
create policy "profiles are readable by authenticated users"
  on public.profiles for select to authenticated using (true);

create policy "users insert their own profile"
  on public.profiles for insert to authenticated with check (id = auth.uid());

create policy "users update their own profile"
  on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- spots: the visibility rule from the web app's CONTEXT.md, verbatim --
-- private owned spots still render on the map (in the "owned by me"
-- pin color), just invisible to everyone else.
create policy "public spots are readable by anyone; private only by owner"
  on public.spots for select to authenticated, anon
  using (is_public or owner_id = auth.uid());

create policy "signed-in users create spots they own"
  on public.spots for insert to authenticated
  with check (owner_id = auth.uid());

create policy "owners update their spots"
  on public.spots for update to authenticated
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create policy "owners delete their spots"
  on public.spots for delete to authenticated
  using (owner_id = auth.uid());

-- RLS can't restrict columns, only rows -- rating and status are
-- display-only in every screen that shows them, so enforce that with a
-- column-level GRANT rather than trusting the client.
revoke update on public.spots from authenticated;
grant update (name, city, spot_type, description, features, difficulty,
              is_skateable, is_public, lat, lng, photo) on public.spots to authenticated;

-- bookmarks: own rows only, and never your own spot.
create policy "users read their own bookmarks"
  on public.bookmarks for select to authenticated using (user_id = auth.uid());

create policy "users bookmark spots they do not own"
  on public.bookmarks for insert to authenticated
  with check (user_id = auth.uid()
              and public.spot_owner_id(spot_id) is distinct from auth.uid());

create policy "users delete their own bookmarks"
  on public.bookmarks for delete to authenticated using (user_id = auth.uid());
-- no update policy: a bookmark has nothing mutable

-- conversations / participants / messages: all routed through the
-- is_conversation_participant() security-definer helper to avoid RLS
-- self-recursion on conversation_participants.
create policy "participants read their conversations"
  on public.conversations for select to authenticated
  using (public.is_conversation_participant(id, auth.uid()));
-- no insert/update/delete policy: creation goes through
-- start_conversation(), last_message_at through a definer trigger.

create policy "participants read the participant list"
  on public.conversation_participants for select to authenticated
  using (public.is_conversation_participant(conversation_id, auth.uid()));

create policy "users update only their own read receipt"
  on public.conversation_participants for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "participants read messages"
  on public.messages for select to authenticated
  using (public.is_conversation_participant(conversation_id, auth.uid()));

-- Sharing a *private* spot in a message is blocked here rather than
-- left to fail silently: without this check, the recipient's own spots
-- SELECT policy hides the shared spot, producing an unrenderable card
-- instead of a clear error at send time.
create policy "participants send messages as themselves"
  on public.messages for insert to authenticated
  with check (
    sender_id = auth.uid()
    and public.is_conversation_participant(conversation_id, auth.uid())
    and (
      shared_spot_id is null
      or exists (select 1 from public.spots s where s.id = shared_spot_id and s.is_public)
    )
  );

create policy "senders delete their own messages"
  on public.messages for delete to authenticated using (sender_id = auth.uid());
-- no update policy: the design has no message-editing affordance
