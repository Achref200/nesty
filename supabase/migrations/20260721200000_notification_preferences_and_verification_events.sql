-- ============================================================================
-- Nesty — member-controlled inbox notifications for verification decisions
-- ============================================================================

create table if not exists public.notification_preferences (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  inbox_enabled boolean not null default true,
  updated_at timestamptz not null default now()
);

alter table public.notification_preferences enable row level security;

drop policy if exists "Users manage their notification preferences"
  on public.notification_preferences;
create policy "Users manage their notification preferences"
  on public.notification_preferences for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create or replace function public.notify_member_verification_decision()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status is distinct from old.status
     and new.status in ('verified', 'rejected')
     and coalesce(
       (select inbox_enabled
          from public.notification_preferences
         where user_id = new.user_id),
       true
     ) then
    insert into public.notifications (user_id, type, title, body)
    values (
      new.user_id,
      'verification_' || new.status,
      case new.status
        when 'verified' then 'Identity verified'
        else 'Verification needs attention'
      end,
      case new.status
        when 'verified' then 'Your identity is verified. Your Nesty badge is now active.'
        else coalesce(new.review_note, 'Please review your submitted identity details and try again.')
      end
    );
  end if;
  return new;
end;
$$;

drop trigger if exists trg_notify_member_verification_decision on public.verifications;
create trigger trg_notify_member_verification_decision
  after update on public.verifications
  for each row execute function public.notify_member_verification_decision();
