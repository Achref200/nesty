-- ============================================================================
-- Nesty — listing analytics + control.
-- Adds per-listing status & tags, and an events table that records every view,
-- save, tour and reservation so the agency dashboard can show what's working.
-- Run in the Supabase SQL editor.
-- ============================================================================

alter table public.listings
  add column if not exists status text not null default 'active'
    check (status in ('active', 'hidden')),
  add column if not exists tags text[] not null default '{}';

create table if not exists public.listing_events (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings (id) on delete cascade,
  host_id uuid references public.profiles (id) on delete set null,
  user_id uuid references public.profiles (id) on delete set null,
  type text not null check (type in ('view', 'save', 'unsave', 'tour', 'reservation')),
  created_at timestamptz not null default now()
);

alter table public.listing_events enable row level security;

create index if not exists listing_events_listing_idx
  on public.listing_events (listing_id);
create index if not exists listing_events_host_idx
  on public.listing_events (host_id);

-- Anyone (even anonymous) may log an event; a host reads events for their own
-- listings only.
create policy "Anyone can log a listing event"
  on public.listing_events for insert with check (true);
create policy "Hosts read events on their listings"
  on public.listing_events for select using (auth.uid() = host_id);

-- Fill host_id from the listing so clients don't send it (and can't spoof it).
create or replace function public.set_event_host()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  select host_id into new.host_id from public.listings where id = new.listing_id;
  return new;
end;
$$;

drop trigger if exists listing_events_set_host on public.listing_events;
create trigger listing_events_set_host before insert on public.listing_events
  for each row execute function public.set_event_host();
