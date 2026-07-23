-- ============================================================================
-- Nesty Base — secure verification submission contract
--
-- The original owner-all policy allowed a member to update `status` directly.
-- This migration replaces it with a narrow read-only owner policy plus a single
-- SECURITY DEFINER RPC. The RPC accepts only the caller's own storage paths and
-- always resets the submission to `pending`; only a super-admin may review it.
-- Apply AFTER 20260721120000_super_admin.sql.
-- ============================================================================

-- Remove the broad owner policy from the original migration.
drop policy if exists "Users manage their own verification" on public.verifications;

-- A member can see their current decision, but cannot directly write a review.
create policy "Users can read their own verification"
  on public.verifications for select
  using (auth.uid() = user_id);

create or replace function public.submit_verification(
  p_full_name text,
  p_phone text,
  p_doc_type text,
  p_doc_front_path text,
  p_doc_back_path text default null,
  p_selfie_path text default null
)
returns public.verifications
language plpgsql
security definer
set search_path = public
as $$
declare
  caller_id uuid := auth.uid();
  submitted public.verifications;
begin
  if caller_id is null then
    raise exception 'Sign in is required to submit verification.';
  end if;

  if p_doc_type not in ('national_id', 'passport', 'driver_license') then
    raise exception 'Unsupported identity document type.';
  end if;

  if coalesce(length(trim(p_full_name)), 0) < 3
     or coalesce(length(trim(p_phone)), 0) < 6
     or coalesce(length(trim(p_doc_front_path)), 0) = 0
     or coalesce(length(trim(p_selfie_path)), 0) = 0 then
    raise exception 'A full name, phone, ID front and selfie are required.';
  end if;

  -- Every referenced file must belong to the authenticated member's private
  -- verification folder. A client cannot attach another person's documents.
  if p_doc_front_path !~ ('^' || caller_id::text || '/')
     or (p_doc_back_path is not null and p_doc_back_path !~ ('^' || caller_id::text || '/'))
     or p_selfie_path !~ ('^' || caller_id::text || '/') then
    raise exception 'Verification documents must belong to the signed-in member.';
  end if;

  insert into public.verifications (
    user_id, full_name, phone, doc_type, doc_front_url, doc_back_url, selfie_url,
    status, reviewer_id, review_note, submitted_at, reviewed_at
  ) values (
    caller_id, trim(p_full_name), trim(p_phone), p_doc_type, p_doc_front_path,
    p_doc_back_path, p_selfie_path, 'pending', null, null, now(), null
  )
  on conflict (user_id) do update set
    full_name = excluded.full_name,
    phone = excluded.phone,
    doc_type = excluded.doc_type,
    doc_front_url = excluded.doc_front_url,
    doc_back_url = excluded.doc_back_url,
    selfie_url = excluded.selfie_url,
    status = 'pending',
    reviewer_id = null,
    review_note = null,
    submitted_at = now(),
    reviewed_at = null
  returning * into submitted;

  return submitted;
end;
$$;

revoke all on function public.submit_verification(text, text, text, text, text, text) from public;
grant execute on function public.submit_verification(text, text, text, text, text, text) to authenticated;

-- Publish review decisions to the member app. The catalog check makes this safe
-- for local environments where the table was already added manually.
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'verifications'
  ) then
    alter publication supabase_realtime add table public.verifications;
  end if;
end;
$$;
