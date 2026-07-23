-- ============================================================================
-- Nesty Base — first-admin bootstrap
-- Removes all seeding friction: the FIRST person to sign in (via GitHub or
-- email) automatically becomes the 'owner'. Once any admin exists, this can no
-- longer grant access — new staff must be added by an existing admin. Safe to
-- run any time; run AFTER 20260721120000_super_admin.sql.
-- ============================================================================

create or replace function public.claim_first_admin(p_github_login text default null)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  me uuid := auth.uid();
  any_admin boolean;
begin
  if me is null then
    return false;
  end if;

  select exists (select 1 from public.super_admins) into any_admin;

  -- Someone already owns the console: only confirm existing membership,
  -- never grant. This closes the bootstrap door after the first admin.
  if any_admin then
    return exists (select 1 from public.super_admins where user_id = me);
  end if;

  -- Empty roster: the caller claims ownership.
  insert into public.super_admins (user_id, email, github_login, role)
  select me, u.email, p_github_login, 'owner'
  from auth.users u
  where u.id = me
  on conflict (user_id) do nothing;

  return true;
end;
$$;

grant execute on function public.claim_first_admin(text) to authenticated;
