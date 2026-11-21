-- Live chat: add messages to the realtime publication. RLS on messages
-- (from the previous migration) is applied per subscriber automatically,
-- so a participant only ever receives rows from their own conversations.
-- replica identity stays default (we only need INSERTs; the design has
-- no edit/delete-in-flight for messages, so FULL would stream whole old
-- rows for no reason).
alter publication supabase_realtime add table public.messages;

-- "Skating now" presence: Realtime Presence over private channels
-- (presence:city:{slug}), not a persisted DB column -- see the plan's
-- schema-decisions notes for why (stale-state risk, live-location
-- privacy, zero write amplification). These policies authorize joining
-- and publishing on any presence:* topic; the channel's own topic
-- scoping (one channel per city) bounds fan-out, not RLS.
create policy "authenticated users join presence topics"
  on realtime.messages for select to authenticated
  using (realtime.topic() like 'presence:%');

create policy "authenticated users publish presence"
  on realtime.messages for insert to authenticated
  with check (realtime.topic() like 'presence:%');
