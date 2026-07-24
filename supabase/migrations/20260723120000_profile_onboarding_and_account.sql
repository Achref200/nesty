-- ============================================================================
-- Nesty — profile onboarding answers, optional ban flags, and self-service
-- account deletion.
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
  select coalesce(
    (
      select
        p.status = 'active'
        and (p.banned_until is null or p.banned_until <= now())
      from public.profiles p
      where p.id = p_id
    ),
    true
  );
$$;

-- --------------------------------------------- self-service deletion ----------
-- Lets a signed-in member permanently delete their own account from the app's
-- Settings. Deleting the auth.users row cascades to profiles, listings,
-- reservations, saved_listings, etc. via their `on delete cascade` FKs.
create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;

revoke all on function public.delete_own_account() from public;
grant execute on function public.delete_own_account() to authenticated;
