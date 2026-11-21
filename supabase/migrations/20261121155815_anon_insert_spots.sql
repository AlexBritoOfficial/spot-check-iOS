-- Signed-out visitors can create a Spot on the web app (CONTEXT.md), but
-- the only insert policy on spots so far requires an authenticated owner.
-- This adds the ownerless case alongside it rather than replacing it --
-- an anon submission must leave owner_id null, never spoof one.
create policy "anonymous users create ownerless spots"
  on public.spots for insert to anon
  with check (owner_id is null);
