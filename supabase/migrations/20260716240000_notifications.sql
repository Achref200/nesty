-- ============================================================================
-- Nesty — real notification center
-- ----------------------------------------------------------------------------
-- A notifications table fed by triggers on reservations, so the agency gets a
-- real notification when a seeker requests a visit/stay, and the seeker gets one
-- when the agency confirms/declines/completes it. Row Level Security scopes each
-- user to their own; realtime lets the apps receive them live.
-- Idempotent. Apply in the Supabase SQL editor.
-- ============================================================================

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  type text not null,
  title text not null,
  body text,
  listing_id uuid references public.listings (id) on delete set null,
  reservation_id uuid references public.reservations (id) on delete set null,
  read boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.notifications enable row level security;

create index if not exists notifications_user_idx
  on public.notifications (user_id, created_at desc);

drop policy if exists "Users read own notifications" on public.notifications;
create policy "Users read own notifications"
  on public.notifications for select using (auth.uid() = user_id);

drop policy if exists "Users update own notifications" on public.notifications;
create policy "Users update own notifications"
  on public.notifications for update using (auth.uid() = user_id);

drop policy if exists "Users delete own notifications" on public.notifications;
create policy "Users delete own notifications"
  on public.notifications for delete using (auth.uid() = user_id);

-- Triggers insert on behalf of another user (guest -> host), so they must run
-- SECURITY DEFINER to bypass RLS.
create or replace function public.notify_host_new_reservation()
  returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.host_id is not null then
    insert into public.notifications (user_id, type, title, body, listing_id, reservation_id)
    values (
      new.host_id,
      'reservation_request',
      case when new.type = 'visit' then 'New visit request' else 'New reservation request' end,
      coalesce(new.guest_name, 'A seeker') || ' requested '
        || coalesce((select title from public.listings where id = new.listing_id), 'your place'),
      new.listing_id,
      new.id
    );
  end if;
  return new;
end $$;

create or replace function public.notify_guest_reservation_status()
  returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status is distinct from old.status then
    insert into public.notifications (user_id, type, title, body, listing_id, reservation_id)
    values (
      new.guest_id,
      'reservation_' || new.status,
      case new.status
        when 'confirmed' then 'Reservation confirmed'
        when 'cancelled' then 'Reservation declined'
        when 'completed' then 'Stay completed'
        else 'Reservation updated'
      end,
      'Your request for '
        || coalesce((select title from public.listings where id = new.listing_id), 'a place')
        || ' is now ' || new.status || '.',
      new.listing_id,
      new.id
    );
  end if;
  return new;
end $$;

drop trigger if exists trg_notify_host_new_reservation on public.reservations;
create trigger trg_notify_host_new_reservation
  after insert on public.reservations
  for each row execute function public.notify_host_new_reservation();

drop trigger if exists trg_notify_guest_reservation_status on public.reservations;
create trigger trg_notify_guest_reservation_status
  after update on public.reservations
  for each row execute function public.notify_guest_reservation_status();

-- Enable realtime delivery.
do $$
begin
  begin
    alter publication supabase_realtime add table public.notifications;
  exception when duplicate_object then null;
  end;
end $$;
