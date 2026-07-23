-- ============================================================================
-- Nesty Base — super-admin & operations schema
-- Adds the data layer the internal admin platform ("Nesty Base") runs on, and
-- makes identity verification real (so an admin actually approves it):
--   • super_admins        — the allow-list of Nesty staff who may sign in
--   • is_super_admin()     — RLS helper used across every admin-scoped table
--   • verifications        — user KYC submissions (approved/rejected by admins)
--   • support_tickets      — bug / error / failure reports from agency spaces
--   • ticket_messages      — the conversation thread on a ticket (agency ↔ staff)
--   • activity_events       — lightweight activity/telemetry for admin analytics
-- RLS is enabled on every table; members see only their own rows, super-admins
-- see everything. Apply in the Supabase SQL editor or with `supabase db push`.
-- ============================================================================

-- --------------------------------------------------------- super_admins ------
create table if not exists public.super_admins (
  user_id uuid primary key references auth.users (id) on delete cascade,
  email text,
  github_login text,
  role text not null default 'admin' check (role in ('owner', 'admin', 'support')),
  created_at timestamptz not null default now()
);

alter table public.super_admins enable row level security;

-- Membership is granted out-of-band (SQL editor / service role), never by the
-- client. A helper keeps the "is this caller staff?" check in one place and is
-- SECURITY DEFINER so policies on other tables can call it without recursion.
create or replace function public.is_super_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.super_admins sa where sa.user_id = auth.uid()
  );
$$;

drop policy if exists "Super admins can read the roster" on public.super_admins;
create policy "Super admins can read the roster"
  on public.super_admins for select using (public.is_super_admin());

-- ----------------------------------------------------------- verifications ---
-- One row per user (re-submitting upserts). Documents live in Cloudinary; we
-- only store URLs. The owner manages their own row; staff review it.
create table if not exists public.verifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles (id) on delete cascade,
  full_name text,
  phone text,
  doc_type text check (doc_type in ('national_id', 'passport', 'driver_license')),
  doc_front_url text,
  doc_back_url text,
  selfie_url text,
  status text not null default 'pending'
    check (status in ('pending', 'verified', 'rejected')),
  reviewer_id uuid references auth.users (id),
  review_note text,
  submitted_at timestamptz not null default now(),
  reviewed_at timestamptz
);

alter table public.verifications enable row level security;

create index if not exists verifications_status_idx on public.verifications (status);

drop policy if exists "Users manage their own verification" on public.verifications;
create policy "Users manage their own verification"
  on public.verifications for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
drop policy if exists "Super admins can read all verifications" on public.verifications;
create policy "Super admins can read all verifications"
  on public.verifications for select using (public.is_super_admin());
drop policy if exists "Super admins can review verifications" on public.verifications;
create policy "Super admins can review verifications"
  on public.verifications for update using (public.is_super_admin());

-- Mirror the approved/rejected decision onto the profile so the whole app can
-- show a verified badge with a single boolean read.
alter table public.profiles add column if not exists is_verified boolean not null default false;

create or replace function public.sync_profile_verified()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles
     set is_verified = (new.status = 'verified'),
         updated_at = now()
   where id = new.user_id;
  if new.status in ('verified', 'rejected') and new.reviewed_at is null then
    new.reviewed_at := now();
  end if;
  return new;
end;
$$;

drop trigger if exists trg_sync_profile_verified on public.verifications;
create trigger trg_sync_profile_verified
  before update on public.verifications
  for each row execute function public.sync_profile_verified();

-- ---------------------------------------------------------- support_tickets --
create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles (id) on delete cascade,
  reporter_role text,
  type text not null
    check (type in ('bug', 'error', 'failure', 'feature_request', 'question', 'other')),
  severity text not null default 'medium'
    check (severity in ('low', 'medium', 'high', 'critical')),
  subject text not null,
  description text,
  area text,
  status text not null default 'open'
    check (status in ('open', 'in_progress', 'resolved', 'closed')),
  assignee_id uuid references auth.users (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.support_tickets enable row level security;

create index if not exists support_tickets_reporter_idx on public.support_tickets (reporter_id);
create index if not exists support_tickets_status_idx on public.support_tickets (status);

drop policy if exists "Reporters can create their own tickets" on public.support_tickets;
create policy "Reporters can create their own tickets"
  on public.support_tickets for insert with check (auth.uid() = reporter_id);
drop policy if exists "Reporters can read their own tickets" on public.support_tickets;
create policy "Reporters can read their own tickets"
  on public.support_tickets for select using (auth.uid() = reporter_id);
drop policy if exists "Super admins can read all tickets" on public.support_tickets;
create policy "Super admins can read all tickets"
  on public.support_tickets for select using (public.is_super_admin());
drop policy if exists "Super admins can update tickets" on public.support_tickets;
create policy "Super admins can update tickets"
  on public.support_tickets for update using (public.is_super_admin());

-- ---------------------------------------------------------- ticket_messages --
create table if not exists public.ticket_messages (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references public.support_tickets (id) on delete cascade,
  author_id uuid not null references auth.users (id),
  body text not null,
  is_staff boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.ticket_messages enable row level security;

create index if not exists ticket_messages_ticket_idx on public.ticket_messages (ticket_id);

-- A caller may see/append to a thread if they own the ticket or are staff.
drop policy if exists "Ticket participants can read messages" on public.ticket_messages;
create policy "Ticket participants can read messages"
  on public.ticket_messages for select
  using (
    public.is_super_admin()
    or exists (
      select 1 from public.support_tickets t
      where t.id = ticket_messages.ticket_id and t.reporter_id = auth.uid()
    )
  );
drop policy if exists "Ticket participants can post messages" on public.ticket_messages;
create policy "Ticket participants can post messages"
  on public.ticket_messages for insert
  with check (
    author_id = auth.uid()
    and (
      public.is_super_admin()
      or exists (
        select 1 from public.support_tickets t
        where t.id = ticket_messages.ticket_id and t.reporter_id = auth.uid()
      )
    )
  );

-- ---------------------------------------------------------- activity_events --
-- Lightweight, append-only telemetry for the admin dashboards (posts over time,
-- most-active agencies, error rates). Anyone signed-in can log their own event;
-- only staff can read the stream.
create table if not exists public.activity_events (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles (id) on delete set null,
  type text not null,
  area text,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now()
);

alter table public.activity_events enable row level security;

create index if not exists activity_events_type_idx on public.activity_events (type);
create index if not exists activity_events_created_idx on public.activity_events (created_at);
create index if not exists activity_events_actor_idx on public.activity_events (actor_id);

drop policy if exists "Signed-in members can log their own activity" on public.activity_events;
create policy "Signed-in members can log their own activity"
  on public.activity_events for insert with check (auth.uid() = actor_id);
drop policy if exists "Super admins can read all activity" on public.activity_events;
create policy "Super admins can read all activity"
  on public.activity_events for select using (public.is_super_admin());

-- --------------------------------------------------- verification storage ---
-- A private bucket for KYC documents. Files are namespaced by the owner's uid
-- ("{uid}/front.jpg"), so a member can only write inside their own folder;
-- super-admins read everything through the service role / signed URLs.
insert into storage.buckets (id, name, public)
values ('verification-docs', 'verification-docs', false)
on conflict (id) do nothing;

drop policy if exists "Members upload their own verification docs" on storage.objects;
create policy "Members upload their own verification docs"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'verification-docs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Members update their own verification docs" on storage.objects;
create policy "Members update their own verification docs"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'verification-docs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Members read their own verification docs" on storage.objects;
create policy "Members read their own verification docs"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'verification-docs'
    and (
      (storage.foldername(name))[1] = auth.uid()::text
      or public.is_super_admin()
    )
  );

-- ----------------------------------------------------------------------------
-- SEED YOUR FIRST ADMIN (run once, after you have signed in to Nesty Base at
-- least once with GitHub so an auth.users row exists for you):
--
--   insert into public.super_admins (user_id, email, github_login, role)
--   select id, email, raw_user_meta_data->>'user_name', 'owner'
--   from auth.users
--   where email = 'YOUR_GITHUB_EMAIL_HERE'
--   on conflict (user_id) do nothing;
-- ----------------------------------------------------------------------------
