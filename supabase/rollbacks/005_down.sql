-- ROLLBACK for 005_business_profile_settings.sql
-- Removes timezone and currency (their values are lost) and restores the five-value business_type rule.
drop trigger if exists businesses_validate_timezone on public.businesses;
drop function if exists public.businesses_validate_timezone();
alter table public.businesses drop column if exists timezone;
alter table public.businesses drop column if exists currency;
update public.businesses set business_type = 'other'
  where business_type is null or business_type not in ('retail', 'services', 'wholesale', 'food', 'other');
alter table public.businesses drop constraint if exists businesses_business_type_check;
alter table public.businesses add constraint businesses_business_type_check
  check (business_type in ('retail', 'services', 'wholesale', 'food', 'other'));
alter table public.businesses alter column business_type set not null;
