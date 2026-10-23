begin;

select plan(4);

insert into auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    '44444444-4444-4444-4444-444444444441',
    'authenticated', 'authenticated', 'listing-host-a@example.test', '', now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '44444444-4444-4444-4444-444444444442',
    'authenticated', 'authenticated', 'listing-host-b@example.test', '', now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now()
  );

insert into public.listings (id, host_id, title, city, status, is_demo)
values
  (
    '55555555-5555-5555-5555-555555555551',
    '44444444-4444-4444-4444-444444444441',
    'Published listing', 'Sousse', 'published', false
  ),
  (
    '55555555-5555-5555-5555-555555555552',
    '44444444-4444-4444-4444-444444444441',
    'Host A draft', 'Sousse', 'draft', false
  ),
  (
    '55555555-5555-5555-5555-555555555553',
    '44444444-4444-4444-4444-444444444442',
    'Host B draft', 'Sousse', 'pending_moderation', false
  ),
  (
    '55555555-5555-5555-5555-555555555554',
    '44444444-4444-4444-4444-444444444442',
    'Host B demo preview', 'Sousse', 'published', true
  );

select ok(
  (select relrowsecurity from pg_class where oid = 'public.listings'::regclass),
  'RLS is enabled for listings'
);

set local role anon;
select set_config('request.jwt.claim.sub', '', true);
select results_eq(
  $$
    select title
      from public.listings
     where id between '55555555-5555-5555-5555-555555555551'::uuid
                   and '55555555-5555-5555-5555-555555555554'::uuid
     order by title
  $$,
  array['Published listing']::text[],
  'anonymous visitors only see published non-demo listings'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '44444444-4444-4444-4444-444444444441', true);
select results_eq(
  $$
    select title
      from public.listings
     where id between '55555555-5555-5555-5555-555555555551'::uuid
                   and '55555555-5555-5555-5555-555555555554'::uuid
     order by title
  $$,
  array['Host A draft', 'Published listing']::text[],
  'an agency can see its draft and published listings'
);

select set_config('request.jwt.claim.sub', '44444444-4444-4444-4444-444444444442', true);
select results_eq(
  $$
    select title
      from public.listings
     where id between '55555555-5555-5555-5555-555555555551'::uuid
                   and '55555555-5555-5555-5555-555555555554'::uuid
     order by title
  $$,
  array['Host B demo preview', 'Host B draft', 'Published listing']::text[],
  'an agency can see its own unpublished and demo inventory'
);

select * from finish();
rollback;
