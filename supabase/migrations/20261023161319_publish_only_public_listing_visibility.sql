-- Keep listing visibility safe even when callers query Supabase directly.
-- The app filters its catalog to published rows, but client-side filters alone
-- do not protect drafts or synthetic previews exposed through the Data API.

drop policy if exists "Listings are viewable by everyone" on public.listings;
drop policy if exists listings_select on public.listings;

create policy "Visitors see published non-demo listings; owners see all"
  on public.listings for select to anon, authenticated
  using (
    (status in ('published', 'active') and is_demo = false)
    or auth.uid() = host_id
  );
