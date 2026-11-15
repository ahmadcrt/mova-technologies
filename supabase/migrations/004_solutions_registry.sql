-- MOVA platform, stage S1: solutions registry.
-- Adds (1) a private "platform" schema for global reference data and (2) public.business_solutions,
-- which records which solutions each business has switched on. Existing tables and data are not changed.
-- Rollback: supabase/rollbacks/004_down.sql

-- ---------------------------------------------------------------- global platform schema (never exposed to the API)
create schema if not exists platform;
revoke all on schema platform from public, anon, authenticated;

create table if not exists platform.solutions (
  key         text primary key check (key ~ '^[a-z][a-z0-9_]{1,30}$'),
  name        text not null check (char_length(name) between 1 and 80),
  status      text not null check (status in ('available', 'in_development', 'planned')),
  sensitivity text not null check (sensitivity in ('standard', 'sensitive')),
  description text check (description is null or char_length(description) <= 300),
  sort_order  integer not null default 100,
  created_at  timestamptz not null default now()
);
alter table platform.solutions enable row level security;
revoke all on platform.solutions from public, anon, authenticated;

insert into platform.solutions (key, name, status, sensitivity, description, sort_order) values
  ('supermarket', 'MOVA Supermarket', 'in_development', 'standard',  'Point of sale, barcode scanning, inventory, suppliers, sales and stock management.', 10),
  ('pharmacy',    'MOVA Pharmacy',    'planned',        'standard',  'Medicine inventory, batches, expiry tracking, sales and suppliers.', 20),
  ('fashion',     'MOVA Fashion',     'planned',        'standard',  'Clothing inventory, sizes, colours, sales and customers.', 30),
  ('restaurant',  'MOVA Restaurant',  'planned',        'standard',  'Point of sale, tables, menus, kitchen orders, inventory and deliveries.', 40),
  ('hotel',       'MOVA Hotel',       'planned',        'standard',  'Reservations, rooms, guests, check-in and check-out, housekeeping and payments.', 50),
  ('school',      'MOVA School',      'planned',        'sensitive', 'Students, teachers, examinations, attendance, fees, admissions and administration.', 60),
  ('hospital',    'MOVA Hospital and Clinic', 'planned', 'sensitive', 'Patients, appointments, records, billing and administration.', 70)
on conflict (key) do update
  set name = excluded.name, status = excluded.status, sensitivity = excluded.sensitivity,
      description = excluded.description, sort_order = excluded.sort_order;

-- ---------------------------------------------------------------- which solutions a business has switched on
create table if not exists public.business_solutions (
  business_id  uuid not null references public.businesses (id) on delete cascade,
  solution_key text not null references platform.solutions (key) on delete restrict,
  status       text not null default 'active' check (status in ('active', 'suspended')),
  enabled_at   timestamptz not null default now(),
  enabled_by   uuid references auth.users (id) on delete set null default auth.uid(),
  primary key (business_id, solution_key)
);
alter table public.business_solutions enable row level security;
revoke all on public.business_solutions from anon, authenticated;
grant select on public.business_solutions to authenticated;

drop policy if exists "business_solutions: members read" on public.business_solutions;
create policy "business_solutions: members read" on public.business_solutions for select to authenticated
  using (public.is_member(business_id));
-- No insert, update or delete policy: changes go only through enable_solution() and disable_solution().

-- ---------------------------------------------------------------- functions
create or replace function public.has_solution(b uuid, s text)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.business_solutions bs
    where bs.business_id = b and bs.solution_key = s and bs.status = 'active' and public.is_member(b));
$$;

create or replace function public.list_solutions()
returns table (key text, name text, status text, sensitivity text, description text, sort_order integer, can_enable boolean)
language sql stable security definer set search_path = '' as $$
  select s.key, s.name, s.status, s.sensitivity, s.description, s.sort_order,
         (s.status in ('available', 'in_development') and s.sensitivity = 'standard') as can_enable
  from platform.solutions s
  where auth.uid() is not null
  order by s.sort_order;
$$;

create or replace function public.enable_solution(p_business uuid, p_solution text)
returns void language plpgsql security definer set search_path = '' as $$
declare
  sol record;
begin
  if auth.uid() is null then raise exception 'Not signed in' using errcode = '28000'; end if;
  if not public.has_role(p_business, array['owner']) then raise exception 'Only the owner can change solutions' using errcode = '42501'; end if;
  select * into sol from platform.solutions where key = p_solution;
  if not found then raise exception 'Unknown solution' using errcode = '22023'; end if;
  if sol.sensitivity <> 'standard' then raise exception 'This solution needs a compliance review before it can be enabled' using errcode = '22023'; end if;
  if sol.status not in ('available', 'in_development') then raise exception 'This solution is not available yet' using errcode = '22023'; end if;
  insert into public.business_solutions (business_id, solution_key, status) values (p_business, p_solution, 'active')
  on conflict (business_id, solution_key) do update set status = 'active';
end;
$$;

create or replace function public.disable_solution(p_business uuid, p_solution text)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then raise exception 'Not signed in' using errcode = '28000'; end if;
  if not public.has_role(p_business, array['owner']) then raise exception 'Only the owner can change solutions' using errcode = '42501'; end if;
  update public.business_solutions set status = 'suspended' where business_id = p_business and solution_key = p_solution;
end;
$$;

revoke all on function public.has_solution(uuid, text) from public, anon;
revoke all on function public.list_solutions() from public, anon;
revoke all on function public.enable_solution(uuid, text) from public, anon;
revoke all on function public.disable_solution(uuid, text) from public, anon;
grant execute on function public.has_solution(uuid, text) to authenticated;
grant execute on function public.list_solutions() to authenticated;
grant execute on function public.enable_solution(uuid, text) to authenticated;
grant execute on function public.disable_solution(uuid, text) to authenticated;
