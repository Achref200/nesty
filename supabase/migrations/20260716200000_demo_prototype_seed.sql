-- ============================================================================
-- Nesty — full prototype demo data (presentable end-to-end example)
-- ----------------------------------------------------------------------------
-- Brings the whole product to life for a demo: two real seeker logins, a spread
-- of reservations (pending / confirmed / completed / cancelled, visits & stays),
-- saved homes, richer analytics events and a marketing waitlist — all wired to
-- the agency and the seeded catalog. After this, the WEB dashboard shows real
-- requests + analytics and the MOBILE app shows real trips & saved homes.
--
-- Run order: 20260716120000_init -> 140000_location -> 160000_analytics
--            -> 180000_rental_term_and_seed -> THIS FILE.
-- Idempotent: fixed ids + guards, safe to run multiple times.
--
-- Demo logins (email / password):
--   agency@nesty.tn         / Nesty#Agency2026   (host — provisioned earlier)
--   ahmed.seeker@nesty.tn   / Nesty#Demo2026     (seeker)
--   salma.seeker@nesty.tn   / Nesty#Demo2026     (seeker)
-- ============================================================================

create extension if not exists pgcrypto;

do $$
declare
  r record;
  v_host uuid;
  v_ahmed uuid := '22222222-2222-2222-2222-222222222201';
  v_salma uuid := '22222222-2222-2222-2222-222222222202';
begin
  -- ----------------------------------------------------------- seekers ------
  -- Create real auth users so the demo seekers can actually sign in. The
  -- handle_new_user trigger creates their public.profiles row from metadata.
  for r in (
    values
      (v_ahmed, 'ahmed.seeker@nesty.tn', 'Ahmed Ben Salah'),
      (v_salma, 'salma.seeker@nesty.tn', 'Salma Trabelsi')
  ) as t(id, email, full_name)
  loop
    if not exists (select 1 from auth.users where id = r.id) then
      insert into auth.users (
        instance_id, id, aud, role, email, encrypted_password,
        email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
        created_at, updated_at,
        confirmation_token, recovery_token, email_change_token_new, email_change
      ) values (
        '00000000-0000-0000-0000-000000000000', r.id, 'authenticated',
        'authenticated', r.email, crypt('Nesty#Demo2026', gen_salt('bf')),
        now(), '{"provider":"email","providers":["email"]}'::jsonb,
        jsonb_build_object('full_name', r.full_name, 'role', 'seeker'),
        now(), now(), '', '', '', ''
      );
      insert into auth.identities (
        provider_id, user_id, identity_data, provider,
        last_sign_in_at, created_at, updated_at
      ) values (
        r.id::text, r.id,
        jsonb_build_object('sub', r.id::text, 'email', r.email,
                           'email_verified', true),
        'email', now(), now(), now()
      );
    end if;
  end loop;

  -- Make sure the profiles exist even if the trigger didn't fire.
  insert into public.profiles (id, email, full_name, role)
  values
    (v_ahmed, 'ahmed.seeker@nesty.tn', 'Ahmed Ben Salah', 'seeker'),
    (v_salma, 'salma.seeker@nesty.tn', 'Salma Trabelsi', 'seeker')
  on conflict (id) do update
    set full_name = excluded.full_name, email = excluded.email;

  -- --------------------------------------------------------- the agency -----
  select id into v_host
    from public.profiles
   where role = 'host'
   order by created_at
   limit 1;

  if v_host is null then
    raise notice 'No host profile — run the catalog seed first. Skipping.';
    return;
  end if;

  -- --------------------------------------------------------- reservations ---
  -- A realistic mix so the dashboard "Requests", "Calendar" and the seekers'
  -- "Trips" all have content. host_id is set directly (and by trigger).
  insert into public.reservations (
    id, listing_id, host_id, guest_id, guest_name,
    type, start_at, end_at, guests, status, note, estimated_total, created_at
  ) values
  -- Ahmed — pending visit to the Lac 2 family apartment
  (
    '33333333-3333-3333-3333-333333333301',
    '11111111-1111-1111-1111-111111111101', v_host, v_ahmed, 'Ahmed Ben Salah',
    'visit', now() + interval '5 days' + interval '11 hours', null, 2,
    'pending', 'Looking for a long-term family home near schools.', null,
    now() - interval '1 day'
  ),
  -- Ahmed — confirmed summer stay in Hammamet
  (
    '33333333-3333-3333-3333-333333333302',
    '11111111-1111-1111-1111-111111111103', v_host, v_ahmed, 'Ahmed Ben Salah',
    'stay', now() + interval '20 days', now() + interval '27 days', 4,
    'confirmed', 'Family holiday, two kids.', 747, now() - interval '2 days'
  ),
  -- Salma — pending visit to the Sousse student studio
  (
    '33333333-3333-3333-3333-333333333303',
    '11111111-1111-1111-1111-111111111102', v_host, v_salma, 'Salma Trabelsi',
    'visit', now() + interval '2 days' + interval '14 hours', null, 1,
    'pending', 'Starting the university year, need it furnished.', null,
    now() - interval '6 hours'
  ),
  -- Salma — confirmed visit to the Sfax city apartment (tomorrow)
  (
    '33333333-3333-3333-3333-333333333304',
    '11111111-1111-1111-1111-111111111106', v_host, v_salma, 'Salma Trabelsi',
    'visit', now() + interval '1 day' + interval '16 hours', null, 1,
    'confirmed', null, null, now() - interval '3 days'
  ),
  -- Ahmed — completed stay at the Djerba villa (last month)
  (
    '33333333-3333-3333-3333-333333333305',
    '11111111-1111-1111-1111-111111111105', v_host, v_ahmed, 'Ahmed Ben Salah',
    'stay', now() - interval '40 days', now() - interval '33 days', 5,
    'completed', 'Great stay, thanks!', 1213, now() - interval '55 days'
  ),
  -- Salma — cancelled visit to the Tunis colocation
  (
    '33333333-3333-3333-3333-333333333306',
    '11111111-1111-1111-1111-111111111104', v_host, v_salma, 'Salma Trabelsi',
    'visit', now() - interval '3 days', null, 1,
    'cancelled', null, null, now() - interval '8 days'
  )
  on conflict (id) do nothing;

  -- --------------------------------------------------------- saved homes ----
  insert into public.saved_listings (user_id, listing_id)
  values
    (v_ahmed, '11111111-1111-1111-1111-111111111101'),
    (v_ahmed, '11111111-1111-1111-1111-111111111103'),
    (v_ahmed, '11111111-1111-1111-1111-111111111105'),
    (v_salma, '11111111-1111-1111-1111-111111111102'),
    (v_salma, '11111111-1111-1111-1111-111111111106')
  on conflict (user_id, listing_id) do nothing;

  -- ------------------------------------------------------- analytics events -
  -- Views/saves/tours per listing so the dashboard analytics look alive. The
  -- set_event_host trigger fills host_id from the listing.
  insert into public.listing_events (listing_id, user_id, type)
  select l.id, g.uid, e.type
    from public.listings l
    cross join (values (v_ahmed), (v_salma), (null::uuid)) as g(uid)
    cross join (values ('view'),('view'),('save'),('tour')) as e(type)
   where l.host_id = v_host;

  -- ------------------------------------------------------------- waitlist ---
  insert into public.waitlist (email, source)
  select v.email, 'demo_seed'
    from (values
      ('yosra.demo@example.tn'),
      ('mehdi.demo@example.tn'),
      ('nour.demo@example.tn')
    ) as v(email)
   where not exists (
     select 1 from public.waitlist w where w.email = v.email
   );
end $$;
