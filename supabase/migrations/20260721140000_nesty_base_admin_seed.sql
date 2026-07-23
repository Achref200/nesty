-- ============================================================================
-- Nesty Base — seed the first super-admin (email + password login)
-- Creates a staff account you can sign in with immediately, no GitHub OAuth
-- setup required, and adds it to the super_admins allow-list.
--
--   Email:    admin@nesty.tn
--   Password: ChangeMe#Base2026
--
-- ⚠  CHANGE THIS PASSWORD after your first sign-in (Supabase → Authentication →
--    Users → admin@nesty.tn → Reset password, or from the app once you build it).
--
-- Idempotent: safe to run more than once. Run AFTER 20260721120000_super_admin.sql.
-- ============================================================================

create extension if not exists pgcrypto;

do $$
declare
  admin_uid uuid;
begin
  select id into admin_uid from auth.users where email = 'admin@nesty.tn';

  if admin_uid is null then
    admin_uid := gen_random_uuid();

    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, created_at, updated_at,
      raw_app_meta_data, raw_user_meta_data
    ) values (
      '00000000-0000-0000-0000-000000000000', admin_uid, 'authenticated',
      'authenticated', 'admin@nesty.tn',
      extensions.crypt('ChangeMe#Base2026', extensions.gen_salt('bf')),
      now(), now(), now(),
      '{"provider":"email","providers":["email"]}',
      '{"full_name":"Nesty Admin"}'
    );

    insert into auth.identities (
      id, user_id, provider_id, identity_data, provider,
      last_sign_in_at, created_at, updated_at
    ) values (
      gen_random_uuid(), admin_uid, admin_uid::text,
      json_build_object('sub', admin_uid::text, 'email', 'admin@nesty.tn'),
      'email', now(), now(), now()
    );
  end if;

  -- Profile row (handle_new_user may already have created one — no-op then).
  insert into public.profiles (id, email, full_name, role)
  values (admin_uid, 'admin@nesty.tn', 'Nesty Admin', 'seeker')
  on conflict (id) do nothing;

  -- The allow-list entry that actually grants access.
  insert into public.super_admins (user_id, email, github_login, role)
  values (admin_uid, 'admin@nesty.tn', null, 'owner')
  on conflict (user_id) do nothing;
end $$;
