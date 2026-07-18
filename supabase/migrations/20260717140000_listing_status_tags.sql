-- ============================================================================
-- Nesty — Listing visibility status + tags
-- Adds the two columns the web dashboard already expects but the DB was missing:
--   * status  — 'active' (live & bookable) or 'hidden' (kept private)
--   * tags    — free-form labels used for marketing / availability filters
-- Fixes the "Could not find the 'status' column of 'listings'" error when a host
-- hides or publishes a listing. Idempotent: safe to re-run.
-- Apply with the Supabase SQL editor or `supabase db push`.
-- Run order: init -> location -> analytics -> rental_term_and_seed ->
--            demo_prototype_seed -> storage -> notifications -> partner_role ->
--            listing_status_tags
-- ============================================================================

alter table public.listings
  add column if not exists status text not null default 'active';

-- Add the check constraint separately so the migration stays idempotent.
alter table public.listings
  drop constraint if exists listings_status_check;
alter table public.listings
  add constraint listings_status_check check (status in ('active', 'hidden'));

alter table public.listings
  add column if not exists tags text[] not null default '{}';

create index if not exists listings_status_idx on public.listings (status);

-- Backfill any pre-existing rows to a sane default.
update public.listings set status = 'active' where status is null;
