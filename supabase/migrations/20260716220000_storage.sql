-- ============================================================================
-- Nesty — Storage bucket for listing photos
-- ----------------------------------------------------------------------------
-- Lets agencies upload photos from their desktop (web) / device (mobile). The
-- uploaded public URLs are stored on listings.cover_image / gallery and feed
-- the 3D tour. Public read; only authenticated users can upload.
-- Idempotent. Apply in the Supabase SQL editor.
-- ============================================================================

insert into storage.buckets (id, name, public)
values ('listing-photos', 'listing-photos', true)
on conflict (id) do nothing;

drop policy if exists "Public read listing photos" on storage.objects;
create policy "Public read listing photos"
  on storage.objects for select
  using (bucket_id = 'listing-photos');

drop policy if exists "Hosts upload listing photos" on storage.objects;
create policy "Hosts upload listing photos"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'listing-photos');

drop policy if exists "Hosts update own listing photos" on storage.objects;
create policy "Hosts update own listing photos"
  on storage.objects for update to authenticated
  using (bucket_id = 'listing-photos' and owner = auth.uid());

drop policy if exists "Hosts delete own listing photos" on storage.objects;
create policy "Hosts delete own listing photos"
  on storage.objects for delete to authenticated
  using (bucket_id = 'listing-photos' and owner = auth.uid());
