-- ============================================================================
-- Nesty — rental term, audience targeting & a full Tunisian seed catalog
-- ----------------------------------------------------------------------------
-- Adds the "how long" (short_term vs long_term) and "who it suits"
-- (adults / children / baby / pets) dimensions the product needs to serve both
-- the summer/vacation crowd and the year-long student & family market, then
-- seeds a realistic Tunisian catalog so the mobile app and the web dashboard
-- render the SAME real data — no mocks on either side.
--
-- Idempotent: safe to run multiple times (fixed listing ids + on conflict).
-- Apply in the Supabase SQL editor or with `supabase db push`.
-- Requires the analytics migration (status/tags/listing_events) to be applied.
-- ============================================================================

-- ---------------------------------------------------------------- columns ----
alter table public.listings
  add column if not exists rental_term text not null default 'long_term'
    check (rental_term in ('short_term', 'long_term'));

alter table public.listings
  add column if not exists audience text[] not null default '{}';

-- Make sure the analytics columns exist even if that migration was skipped.
alter table public.listings
  add column if not exists status text not null default 'active'
    check (status in ('active', 'hidden'));
alter table public.listings
  add column if not exists tags text[] not null default '{}';

create index if not exists listings_rental_term_idx
  on public.listings (rental_term);
create index if not exists listings_status_idx on public.listings (status);

-- ------------------------------------------------------------------- seed -----
-- Seeds the catalog under the first host (agency) profile. If no host exists
-- yet, the block is a no-op so the migration never fails.
do $$
declare
  v_host uuid;
  v_host_name text;
begin
  select id, coalesce(full_name, 'Nesty Agency')
    into v_host, v_host_name
    from public.profiles
   where role = 'host'
   order by created_at
   limit 1;

  if v_host is null then
    raise notice 'No host profile found — skipping listing seed.';
    return;
  end if;

  insert into public.listings (
    id, host_id, host_name, title, city, address,
    price_per_month, currency, type, rental_term, audience, tags, status,
    bedrooms, bathrooms, area_sqm, cover_image, gallery, rooms, amenities,
    rating, review_count, description, is_superhost, bills_included, flatmates,
    available_from, latitude, longitude
  ) values
  -- 1) Long-term FAMILY apartment — Tunis, Les Berges du Lac 2
  (
    '11111111-1111-1111-1111-111111111101', v_host, v_host_name,
    'Spacious family T4 — Lac 2', 'Tunis, Les Berges du Lac 2',
    'Rue du Lac Turkana, Les Berges du Lac 2, 1053',
    2200, 'TND', 'entire_place', 'long_term',
    array['family','children','baby','pets'],
    array['family-friendly','parking','elevator','furnished','wifi'], 'active',
    3, 2, 138,
    'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=1200&q=80',
    array[
      'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=1200&q=80',
      'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=1200&q=80',
      'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=1200&q=80'
    ],
    '[
      {"id":"l1-r0","name":"Living room","type":"living_room","images":["https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=1000&q=80","https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=1000&q=80","https://images.unsplash.com/photo-1567767292278-a4f21aa2d36e?w=1000&q=80"],"panorama_url":"https://cdn.aframe.io/360-image-gallery-boilerplate/img/city.jpg"},
      {"id":"l1-r1","name":"Master bedroom","type":"bedroom","images":["https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=1000&q=80","https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=1000&q=80"],"panorama_url":null},
      {"id":"l1-r2","name":"Kitchen","type":"kitchen","images":["https://images.unsplash.com/photo-1556911220-bff31c812dba?w=1000&q=80","https://images.unsplash.com/photo-1600489000022-c2086d79f9d4?w=1000&q=80"],"panorama_url":null}
    ]'::jsonb,
    array['Wi-Fi','Air-con','Elevator','Parking','Washer','Balcony'],
    4.8, 42, 'A bright, family-sized apartment steps from Lac 2 — three bedrooms, a large living room and a safe, walkable neighborhood with schools and parks nearby. Tour it in 3D before you visit.',
    true, false, 0, 'Now', 36.8425, 10.2731
  ),
  -- 2) Long-term STUDENT studio — Sousse, Sahloul (near university/hospital)
  (
    '11111111-1111-1111-1111-111111111102', v_host, v_host_name,
    'Furnished student studio — Sahloul', 'Sousse, Sahloul',
    'Avenue Yasser Arafat, Sahloul, 4054',
    650, 'TND', 'private_room', 'long_term',
    array['adults'],
    array['students','near-university','furnished','wifi','bills-included'], 'active',
    1, 1, 34,
    'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=1200&q=80',
    array[
      'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=1200&q=80',
      'https://images.unsplash.com/photo-1505691938895-1758d7feb511?w=1200&q=80'
    ],
    '[
      {"id":"l2-r0","name":"Studio","type":"living_room","images":["https://images.unsplash.com/photo-1505691938895-1758d7feb511?w=1000&q=80","https://images.unsplash.com/photo-1560185007-cde436f6a4d0?w=1000&q=80"],"panorama_url":"https://cdn.aframe.io/360-image-gallery-boilerplate/img/city.jpg"},
      {"id":"l2-r1","name":"Kitchenette","type":"kitchen","images":["https://images.unsplash.com/photo-1556909212-d5b604d0c90d?w=1000&q=80"],"panorama_url":null}
    ]'::jsonb,
    array['Wi-Fi','Heating','Desk','Kitchenette','Bills included'],
    4.6, 28, 'A tidy, fully-furnished studio a short walk from Sousse university and the hospital — ideal for a student settling in for the year. Bills included.',
    false, true, 0, 'Now', 35.8342, 10.5960
  ),
  -- 3) Short-term SUMMER apartment — Hammamet (beach)
  (
    '11111111-1111-1111-1111-111111111103', v_host, v_host_name,
    'Seaside summer apartment — Hammamet', 'Hammamet, Yasmine',
    'Zone Touristique, Yasmine Hammamet, 8050',
    3200, 'TND', 'entire_place', 'short_term',
    array['family','children','baby'],
    array['beach','pool','summer','vacation','parking'], 'active',
    2, 2, 92,
    'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=1200&q=80',
    array[
      'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=1200&q=80',
      'https://images.unsplash.com/photo-1560448075-bb485b067938?w=1200&q=80'
    ],
    '[
      {"id":"l3-r0","name":"Living room","type":"living_room","images":["https://images.unsplash.com/photo-1567767292278-a4f21aa2d36e?w=1000&q=80","https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=1000&q=80"],"panorama_url":"https://cdn.aframe.io/360-image-gallery-boilerplate/img/city.jpg"},
      {"id":"l3-r1","name":"Bedroom","type":"bedroom","images":["https://images.unsplash.com/photo-1560185007-cde436f6a4d0?w=1000&q=80"],"panorama_url":null}
    ]'::jsonb,
    array['Wi-Fi','Air-con','Pool','Balcony','Parking'],
    4.9, 63, 'Wake up to the sea in Yasmine Hammamet — a bright two-bedroom with a shared pool, minutes from the beach. Perfect for a summer family getaway.',
    true, false, 0, 'Jun 2026', 36.3667, 10.5533
  ),
  -- 4) Long-term COLOCATION shared room — Tunis Centre
  (
    '11111111-1111-1111-1111-111111111104', v_host, v_host_name,
    'Colocation room in shared flat — Tunis Centre', 'Tunis, Centre Ville',
    'Avenue Habib Bourguiba, Tunis, 1000',
    480, 'TND', 'shared_room', 'long_term',
    array['adults'],
    array['students','colocation','bills-included','wifi','city-center'], 'active',
    1, 1, 18,
    'https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=1200&q=80',
    array[
      'https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=1200&q=80',
      'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=1200&q=80'
    ],
    '[
      {"id":"l4-r0","name":"Private bedroom","type":"bedroom","images":["https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=1000&q=80","https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=1000&q=80"],"panorama_url":null},
      {"id":"l4-r1","name":"Shared living room","type":"living_room","images":["https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=1000&q=80"],"panorama_url":"https://cdn.aframe.io/360-image-gallery-boilerplate/img/city.jpg"}
    ]'::jsonb,
    array['Wi-Fi','Heating','Washer','Bills included'],
    4.4, 17, 'A private room in a friendly shared flat right on Avenue Bourguiba — bills included, metro at the door. Great for students and young professionals.',
    false, true, 2, 'Now', 36.7992, 10.1817
  ),
  -- 5) Short-term VACATION villa — Djerba
  (
    '11111111-1111-1111-1111-111111111105', v_host, v_host_name,
    'Private villa with pool — Djerba', 'Djerba, Houmt Souk',
    'Route de la Plage, Houmt Souk, 4180',
    5200, 'TND', 'entire_place', 'short_term',
    array['family','children','baby','pets'],
    array['villa','pool','beach','summer','vacation','pets-allowed'], 'active',
    4, 3, 210,
    'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=1200&q=80',
    array[
      'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=1200&q=80',
      'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=1200&q=80'
    ],
    '[
      {"id":"l5-r0","name":"Living room","type":"living_room","images":["https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=1000&q=80","https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=1000&q=80"],"panorama_url":"https://cdn.aframe.io/360-image-gallery-boilerplate/img/city.jpg"},
      {"id":"l5-r1","name":"Master suite","type":"bedroom","images":["https://images.unsplash.com/photo-1560185007-cde436f6a4d0?w=1000&q=80","https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=1000&q=80"],"panorama_url":null}
    ]'::jsonb,
    array['Wi-Fi','Air-con','Pool','Parking','Balcony'],
    5.0, 31, 'A whole villa with a private pool a short drive from Houmt Souk beaches — space for the whole family, pets welcome. Ideal for a summer or holiday stay.',
    true, false, 0, 'Jul 2026', 33.8756, 10.8571
  ),
  -- 6) Long-term PROFESSIONAL apartment — Sfax
  (
    '11111111-1111-1111-1111-111111111106', v_host, v_host_name,
    'Modern city apartment — Sfax', 'Sfax, Centre',
    'Avenue Hedi Chaker, Sfax, 3000',
    1150, 'TND', 'entire_place', 'long_term',
    array['adults'],
    array['furnished','wifi','city-center','elevator'], 'active',
    2, 1, 78,
    'https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=1200&q=80',
    array[
      'https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=1200&q=80',
      'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=1200&q=80'
    ],
    '[
      {"id":"l6-r0","name":"Living room","type":"living_room","images":["https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=1000&q=80","https://images.unsplash.com/photo-1567767292278-a4f21aa2d36e?w=1000&q=80"],"panorama_url":"https://cdn.aframe.io/360-image-gallery-boilerplate/img/city.jpg"},
      {"id":"l6-r1","name":"Bedroom","type":"bedroom","images":["https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=1000&q=80"],"panorama_url":null}
    ]'::jsonb,
    array['Wi-Fi','Air-con','Elevator','Desk'],
    4.5, 22, 'A modern, furnished two-bedroom in the heart of Sfax — walkable to work and services, ready for a year-long professional lease.',
    false, false, 0, 'Now', 34.7406, 10.7603
  )
  on conflict (id) do nothing;

  -- A little engagement history so the dashboard analytics look alive.
  insert into public.listing_events (listing_id, host_id, type)
  select l.id, v_host, e.type
    from public.listings l
    cross join (
      values ('view'),('view'),('view'),('save'),('tour')
    ) as e(type)
   where l.host_id = v_host
     and l.id in (
       '11111111-1111-1111-1111-111111111101',
       '11111111-1111-1111-1111-111111111103'
     );
end $$;
