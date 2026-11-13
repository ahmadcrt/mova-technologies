-- MOVA platform, Phase 1: accounts, businesses, membership, roles and isolation.
-- Run in the Supabase SQL editor AFTER 001 and 002. Safe to re-run.
-- Rules: every table has Row Level Security; anonymous visitors get nothing; signed-in users see only their own business.

-- ---------------------------------------------------------------- profiles
create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  full_name   text check (full_name is null or char_length(full_name) <= 120),
  phone       text check (phone is null or char_length(phone) <= 30),
  created_at  timestamptz not null default now()
);
alter table public.profiles enable row level security;
revoke all on public.profiles from anon, authenticated;
grant select on public.profiles to authenticated;
grant update (full_name, phone) on public.profiles to authenticated;

drop policy if exists "profiles: read own" on public.profiles;
create policy "profiles: read own" on public.profiles for select to authenticated
  using (id = (select auth.uid()));
drop policy if exists "profiles: update own" on public.profiles;
create policy "profiles: update own" on public.profiles for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

-- create a profile automatically for every new sign-up
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, left(nullif(trim(coalesce(new.raw_user_meta_data ->> 'full_name', '')), ''), 120))
  on conflict (id) do nothing;
  return new;
end;
$$;
revoke all on function public.handle_new_user() from public, anon, authenticated;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();
insert into public.profiles (id) select id from auth.users on conflict (id) do nothing;

-- ---------------------------------------------------------------- businesses
create table if not exists public.businesses (
  id            uuid primary key default gen_random_uuid(),
  owner_id      uuid not null references auth.users (id) on delete restrict,
  name          text not null check (char_length(name) between 1 and 100),
  business_type text not null check (business_type in ('retail', 'services', 'wholesale', 'food', 'other')),
  city_state    text check (city_state is null or char_length(city_state) <= 100),
  team_size     text check (team_size is null or team_size in ('solo', '2-5', '6-20', '21+')),
  phone         text check (phone is null or char_length(phone) <= 30),
  email         text check (email is null or char_length(email) <= 254),
  address       text check (address is null or char_length(address) <= 250),
  logo_path     text check (logo_path is null or char_length(logo_path) <= 300),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create unique index if not exists businesses_one_per_owner on public.businesses (owner_id); -- version 1: one business per owner

create table if not exists public.business_members (
  id          uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses (id) on delete cascade,
  user_id     uuid not null references auth.users (id) on delete cascade,
  role        text not null check (role in ('owner', 'manager', 'employee')),
  created_at  timestamptz not null default now(),
  unique (business_id, user_id)
);
create index if not exists business_members_user_idx on public.business_members (user_id);

-- helper functions used by every policy (security definer avoids recursive policy checks)
create or replace function public.is_member(b uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.business_members m where m.business_id = b and m.user_id = (select auth.uid()));
$$;
create or replace function public.has_role(b uuid, roles text[])
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.business_members m
                 where m.business_id = b and m.user_id = (select auth.uid()) and m.role = any (roles));
$$;
revoke all on function public.is_member(uuid) from public, anon;
revoke all on function public.has_role(uuid, text[]) from public, anon;
grant execute on function public.is_member(uuid) to authenticated;
grant execute on function public.has_role(uuid, text[]) to authenticated;

alter table public.businesses enable row level security;
alter table public.business_members enable row level security;
revoke all on public.businesses from anon, authenticated;
revoke all on public.business_members from anon, authenticated;
grant select on public.businesses to authenticated;
grant update (name, business_type, city_state, team_size, phone, email, address, logo_path) on public.businesses to authenticated;
grant select on public.business_members to authenticated;

drop policy if exists "businesses: members read" on public.businesses;
create policy "businesses: members read" on public.businesses for select to authenticated
  using (public.is_member(id));
drop policy if exists "businesses: owner update" on public.businesses;
create policy "businesses: owner update" on public.businesses for update to authenticated
  using (public.has_role(id, array['owner'])) with check (public.has_role(id, array['owner']));
drop policy if exists "members: members read" on public.business_members;
create policy "members: members read" on public.business_members for select to authenticated
  using (public.is_member(business_id));
-- No insert, update or delete policies on business_members: roles change only through controlled functions (Phase 8).

create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end;
$$;
drop trigger if exists businesses_updated_at on public.businesses;
create trigger businesses_updated_at before update on public.businesses
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------- onboarding
-- The only way to create a business: validates input and creates the business and its owner membership together.
create or replace function public.create_business(p_name text, p_type text, p_city text default null, p_team text default null)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
  nm  text := trim(coalesce(p_name, ''));
  bid uuid;
begin
  if uid is null then raise exception 'Not signed in' using errcode = '28000'; end if;
  if char_length(nm) not between 1 and 100 then raise exception 'Business name must be 1 to 100 characters' using errcode = '22023'; end if;
  if p_type is null or p_type not in ('retail', 'services', 'wholesale', 'food', 'other') then raise exception 'Invalid business type' using errcode = '22023'; end if;
  if p_team is not null and p_team not in ('solo', '2-5', '6-20', '21+') then raise exception 'Invalid team size' using errcode = '22023'; end if;
  if exists (select 1 from public.businesses where owner_id = uid) then raise exception 'You already have a business' using errcode = '23505'; end if;

  insert into public.businesses (owner_id, name, business_type, city_state, team_size)
  values (uid, nm, p_type, nullif(left(trim(coalesce(p_city, '')), 100), ''), p_team)
  returning id into bid;
  insert into public.business_members (business_id, user_id, role) values (bid, uid, 'owner');
  return bid;
end;
$$;
revoke all on function public.create_business(text, text, text, text) from public, anon;
grant execute on function public.create_business(text, text, text, text) to authenticated;
