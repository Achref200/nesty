-- ============================================================================
-- Nesty — Partner role + subscriptions
-- Adds the paid, self-serve "Partner" account type (an independent individual
-- with an owner network — the modern take on the Tunisian "samsar") and the
-- subscription that gates it (standard / premium / customized tiers, billed
-- monthly or yearly). Agencies stay hand-to-hand; Partners pay online.
-- Apply with the Supabase SQL editor or `supabase db push`.
-- Run order: init -> location -> analytics -> rental_term_and_seed ->
--            demo_prototype_seed -> storage -> notifications -> partner_role
-- ============================================================================

-- ------------------------------------------------------- profiles role check -
-- Allow the new 'partner' role alongside seeker/host. Drop then re-add the
-- constraint so this migration is idempotent.
alter table public.profiles
  drop constraint if exists profiles_role_check;
alter table public.profiles
  add constraint profiles_role_check
  check (role in ('seeker', 'host', 'partner'));

-- ------------------------------------------------------------- subscriptions -
-- One active subscription per user. Partners must hold an active row; a seeker
-- upgrading to Partner creates one. Limits are denormalised here so the client
-- can enforce them without a second lookup.
create table if not exists public.subscriptions (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  plan text not null default 'standard'
    check (plan in ('standard', 'premium', 'customized')),
  billing text not null default 'monthly'
    check (billing in ('monthly', 'yearly')),
  status text not null default 'active'
    check (status in ('active', 'cancelled', 'past_due')),
  -- Listings the partner may keep active. -1 means unlimited / admin-defined
  -- (the "customized" tier is negotiated hand-to-hand with an admin).
  listing_limit int not null default 10,
  price numeric,
  current_period_end timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.subscriptions enable row level security;

create policy "Users can view their own subscription"
  on public.subscriptions for select using (auth.uid() = user_id);
create policy "Users can create their own subscription"
  on public.subscriptions for insert with check (auth.uid() = user_id);
create policy "Users can update their own subscription"
  on public.subscriptions for update using (auth.uid() = user_id);
create policy "Users can delete their own subscription"
  on public.subscriptions for delete using (auth.uid() = user_id);

drop trigger if exists subscriptions_set_updated_at on public.subscriptions;
create trigger subscriptions_set_updated_at before update on public.subscriptions
  for each row execute function public.set_updated_at();
