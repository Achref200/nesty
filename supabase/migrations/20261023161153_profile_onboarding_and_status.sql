-- ============================================================================
-- Nesty — profile onboarding answers and optional ban flags.
--
-- Run in the Supabase SQL editor (or `supabase db push`) after the existing
-- migrations. Everything here is additive and idempotent.
-- ============================================================================

-- --------------------------------------------------- profile onboarding ------
-- Answers collected by the first-run "tell us about you" flow in the app.
alter table public.profiles
  add column if not exists country text,
  add column if not exists city text,
  add column if not exists purpose text,
  add column if not exists household text,
  add column if not exists budget_band text,
  add column if not exists preferred_regions text[] not null default '{}',
  add column if not exists onboarding_completed boolean not null default false;

-- ------------------------------------------------ optional ban flags ----------
-- Primary suspension still rides in auth (ban_duration) + app_metadata, which
-- the mobile app reads from the JWT. These columns let the admin console ALSO
-- flag a suspension at the database layer; the app reads them defensively as a
-- fallback. (Enforcing them in RLS is a separate, deliberate step.)
alter table public.profiles
  add column if not exists status text not null default 'active',
  add column if not exists banned_until timestamptz,
  add column if not exists ban_reason text,
  add column if not exists ban_type text;

-- A small helper the console (or future RLS policies) can use.
create or replace function public.is_account_active(p_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when auth.uid() is null then false
    when auth.uid() <> p_id and not public.is_super_admin() then false
    else coalesce((
      select p.status = 'active'
         and (p.banned_until is null or p.banned_until <= now())
        from public.profiles p
       where p.id = p_id
    ), false)
  end;
$$;
revoke all on function public.is_account_active(uuid) from public, anon;
grant execute on function public.is_account_active(uuid) to service_role;
