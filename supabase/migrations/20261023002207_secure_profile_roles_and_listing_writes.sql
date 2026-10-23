-- Harden shared account roles and listing writes.
-- Apply only after reviewing agency/admin flows: those trusted server paths use
-- the service role and remain able to provision host accounts.

-- Admin policies call this helper. Keep its search path fixed and prevent anon
-- callers from using the helper as an account-enumeration endpoint.
create or replace function public.is_super_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.super_admins sa where sa.user_id = auth.uid()
  );
$$;
revoke all on function public.is_super_admin() from public, anon;
grant execute on function public.is_super_admin() to authenticated, service_role;

-- New self-service accounts always start as seekers. Agency roles are written
-- by Nesty Base's service-role provisioning path, never from user metadata.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, email, full_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(coalesce(new.email, ''), '@', 1)),
    'seeker'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
revoke all on function public.handle_new_user() from public, anon, authenticated;

-- Prevent users from changing their own role, verification or suspension flags.
-- A user may still downgrade to seeker. Trusted Nesty Base/service-role changes
-- are unaffected.
create or replace function public.prevent_self_role_promotion()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if auth.uid() = old.id and not public.is_super_admin() then
    if new.role is distinct from old.role and new.role <> 'seeker' then
      raise exception 'Account roles are assigned by Nesty';
    end if;
    if new.status is distinct from old.status
       or new.banned_until is distinct from old.banned_until
       or new.ban_reason is distinct from old.ban_reason
       or new.ban_type is distinct from old.ban_type
       or new.is_verified is distinct from old.is_verified
       or new.email is distinct from old.email then
      raise exception 'Account security fields are managed by Nesty';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_prevent_self_role_promotion on public.profiles;
create trigger profiles_prevent_self_role_promotion
  before update of role, status, banned_until, ban_reason, ban_type, is_verified, email
  on public.profiles
  for each row execute function public.prevent_self_role_promotion();

drop policy if exists "Profiles are viewable by everyone" on public.profiles;
drop policy if exists "Users can insert their own profile" on public.profiles;
drop policy if exists "Users can update their own profile" on public.profiles;

create policy "Users and Nesty admins can read profiles"
  on public.profiles for select to authenticated
  using (auth.uid() = id or public.is_super_admin());
create policy "Users can create seeker profiles"
  on public.profiles for insert to authenticated
  with check (auth.uid() = id and role = 'seeker');
create policy "Users and Nesty admins can update profiles"
  on public.profiles for update to authenticated
  using (auth.uid() = id or public.is_super_admin())
  with check (auth.uid() = id or public.is_super_admin());

-- Supabase Auth's standard helper runs as the caller; it only reads the
-- caller's profile (or a profile for a verified Nesty admin).
create or replace function public.is_account_active(p_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when auth.uid() is null then false
    when auth.uid() <> p_id and not public.is_super_admin() then false
    else coalesce((
      select p.status = 'active'
         and (p.banned_until is null or p.banned_until <= now())
        from public.profiles p
       where p.id = p_id
    ), false)
  end;
$$;
revoke all on function public.is_account_active(uuid) from public, anon;
grant execute on function public.is_account_active(uuid) to authenticated, service_role;

-- Profiles are no longer public; public listing cards use listings.host_name.
-- Public listing reads remain enabled, while listing mutations require a
-- provisioned agency or an active Partner subscription.
drop policy if exists "Hosts can insert their own listings" on public.listings;
drop policy if exists "Hosts can update their own listings" on public.listings;
drop policy if exists "Hosts can delete their own listings" on public.listings;

create policy "Agencies and active partners can publish listings"
  on public.listings for insert to authenticated
  with check (
    auth.uid() = host_id
    and exists (
      select 1 from public.profiles p
       where p.id = auth.uid()
         and (
           p.role = 'host'
           or (
             p.role = 'partner'
             and exists (
               select 1 from public.subscriptions s
                where s.user_id = auth.uid()
                  and s.status = 'active'
                  and (s.current_period_end is null or s.current_period_end > now())
             )
           )
         )
    )
  );

create policy "Agencies and active partners can update listings"
  on public.listings for update to authenticated
  using (
    auth.uid() = host_id
    and exists (
      select 1 from public.profiles p
       where p.id = auth.uid()
         and (
           p.role = 'host'
           or (
             p.role = 'partner'
             and exists (
               select 1 from public.subscriptions s
                where s.user_id = auth.uid()
                  and s.status = 'active'
                  and (s.current_period_end is null or s.current_period_end > now())
             )
           )
         )
    )
  )
  with check (
    auth.uid() = host_id
    and exists (
      select 1 from public.profiles p
       where p.id = auth.uid()
         and (
           p.role = 'host'
           or (
             p.role = 'partner'
             and exists (
               select 1 from public.subscriptions s
                where s.user_id = auth.uid()
                  and s.status = 'active'
                  and (s.current_period_end is null or s.current_period_end > now())
             )
           )
         )
    )
  );

create policy "Users can delete their own listings"
  on public.listings for delete to authenticated
  using (auth.uid() = host_id);

-- Subscription state/quota is not payment proof. Clients may read their own
-- plan and cancel it, but only trusted server code can create or reactivate it.
drop policy if exists "Users can create their own subscription" on public.subscriptions;
drop policy if exists "Users can update their own subscription" on public.subscriptions;
drop policy if exists "Users can delete their own subscription" on public.subscriptions;
create policy "Users can cancel their own subscription"
  on public.subscriptions for update to authenticated
  using (auth.uid() = user_id and status = 'active')
  with check (auth.uid() = user_id and status = 'cancelled');

create or replace function public.prevent_subscription_self_edits()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if auth.uid() = old.user_id and not public.is_super_admin() then
    if old.status <> 'active' or new.status <> 'cancelled'
       or (to_jsonb(new) - 'status' - 'updated_at')
          is distinct from (to_jsonb(old) - 'status' - 'updated_at') then
      raise exception 'Subscription activation and changes are managed by Nesty';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists subscriptions_prevent_self_edits on public.subscriptions;
create trigger subscriptions_prevent_self_edits
  before update on public.subscriptions
  for each row execute function public.prevent_subscription_self_edits();

-- Ensure the reservation trigger does not need elevated database privileges.
create or replace function public.set_reservation_host()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  select l.host_id into new.host_id
    from public.listings l
   where l.id = new.listing_id;
  return new;
end;
$$;
revoke all on function public.set_reservation_host() from public, anon, authenticated;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
