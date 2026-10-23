-- Remove a redundant owner policy and tighten an unused internal helper.
drop policy if exists availability_blocks_select on public.availability_blocks;

alter function public.touch_incident_updated_at() set search_path = '';

revoke all on function public.is_account_active(uuid) from public, anon, authenticated;
grant execute on function public.is_account_active(uuid) to service_role;
