-- ============================================================================
-- Nesty — add exact map coordinates to listings.
-- Run in the Supabase SQL editor (or `supabase db push`).
-- ============================================================================

alter table public.listings
  add column if not exists latitude double precision,
  add column if not exists longitude double precision;
