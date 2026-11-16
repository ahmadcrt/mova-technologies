-- MOVA platform, stage S2: business profile settings.
-- Adds timezone and currency to businesses (defaults: Africa/Lagos, NGN) and relaxes the fixed business_type list.
-- Existing businesses keep all their data; they receive the defaults. Rollback: supabase/rollbacks/005_down.sql

-- 1. business_type: no longer a closed list of five values (solutions now describe what a business does).
alter table public.businesses drop constraint if exists businesses_business_type_check;
alter table public.businesses alter column business_type drop not null;
alter table public.businesses add constraint businesses_business_type_check
  check (business_type is null or business_type ~ '^[a-z][a-z0-9_]{1,30}$');

-- 2. timezone and currency
alter table public.businesses add column if not exists timezone text not null default 'Africa/Lagos'
  check (char_length(timezone) between 1 and 64);
alter table public.businesses add column if not exists currency text not null default 'NGN'
  check (currency ~ '^[A-Z]{3}$');

create or replace function public.businesses_validate_timezone()
returns trigger language plpgsql set search_path = '' as $$
begin
  if not exists (select 1 from pg_catalog.pg_timezone_names where name = new.timezone) then
    raise exception 'Unknown timezone' using errcode = '22023';
  end if;
  return new;
end;
$$;
revoke all on function public.businesses_validate_timezone() from public, anon, authenticated;
drop trigger if exists businesses_validate_timezone on public.businesses;
create trigger businesses_validate_timezone
  before insert or update of timezone on public.businesses
  for each row execute function public.businesses_validate_timezone();

-- 3. the owner may change these (existing owner-only update policy still applies)
grant update (timezone, currency) on public.businesses to authenticated;
