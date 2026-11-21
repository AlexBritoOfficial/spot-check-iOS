-- Chat: conversations + conversation_participants + messages.
--
-- dm_key is the canonical least/greatest pairing of the two user ids,
-- enforced unique, so tapping "Message" twice from SkaterProfile can
-- never create two parallel threads with the same person.
--
-- conversation_participants.last_read_at is what the unread badges on
-- the Menu and the Messages list are computed from.

create table public.conversations (
  id              uuid primary key default gen_random_uuid(),
  created_by      uuid references auth.users(id) on delete set null,
  dm_key          text unique,
  created_at      timestamptz not null default now(),
  last_message_at timestamptz not null default now()
);

create table public.conversation_participants (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id         uuid not null references auth.users(id) on delete cascade,
  joined_at       timestamptz not null default now(),
  last_read_at    timestamptz,
  primary key (conversation_id, user_id)
);

create index conversation_participants_user_idx on public.conversation_participants (user_id);

create table public.messages (
  id              uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id       uuid not null references auth.users(id) on delete cascade,
  body            text,
  -- on delete set null (not cascade): a shared-spot message survives the
  -- spot being deleted -- the bubble just degrades to "Shared a spot"
  -- instead of vanishing from the conversation's history.
  shared_spot_id  uuid references public.spots(id) on delete set null,
  created_at      timestamptz not null default now(),
  constraint messages_has_content check (
    nullif(trim(coalesce(body, '')), '') is not null or shared_spot_id is not null
  )
);

create index messages_conversation_created_idx
  on public.messages (conversation_id, created_at desc);

-- Breaks RLS self-recursion: any policy on conversation_participants that
-- itself queries conversation_participants raises "infinite recursion
-- detected in policy". A security definer function bypasses RLS inside
-- itself, so it can be reused safely by policies on all three tables.
create or replace function public.is_conversation_participant(p_conversation_id uuid, p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.conversation_participants cp
    where cp.conversation_id = p_conversation_id and cp.user_id = p_user_id
  );
$$;

-- Keeps conversations.last_message_at current so the Chats list can sort
-- without a correlated subquery per row. security definer because
-- clients intentionally have no UPDATE policy on conversations.
create or replace function public.bump_conversation_last_message()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.conversations c set last_message_at = new.created_at where c.id = new.conversation_id;
  return new;
end;
$$;

create trigger messages_bump_conversation
  after insert on public.messages
  for each row execute function public.bump_conversation_last_message();
