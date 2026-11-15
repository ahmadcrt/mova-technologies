-- Tests for stage S1 (migration 004): platform schema, registry, business_solutions, isolation. Rolled back at the end.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

create schema t;
create table t.r (k text primary key, v text);
create function t.as_user(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
end $$;
create function t.as_anon() returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', '{"role":"anon"}', true);
  perform set_config('request.jwt.claim.sub', '', true);
  perform set_config('request.jwt.claim.role', 'anon', true);
  set local role anon;
end $$;
create function t.as_admin() returns void language plpgsql as $$ begin reset role; end $$;
create function t.try(sql text) returns text language plpgsql as $$
begin execute sql; return 'ok'; exception when others then return sqlstate; end $$;
grant usage on schema t to anon, authenticated;
grant all on t.r to anon, authenticated;
grant execute on all functions in schema t to anon, authenticated;

insert into auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
 ('a0000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'a@test.local', '', now(), '{}', '{"full_name":"User A"}', now(), now()),
 ('b0000000-0000-0000-0000-00000000000b', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'b@test.local', '', now(), '{}', '{"full_name":"User B"}', now(), now());

-- structure and privileges
select is((select count(*)::int from platform.solutions), 7, 'seven solutions are registered');
select is((select count(*)::int from platform.solutions where sensitivity = 'sensitive' and status = 'planned'), 2, 'School and Hospital are sensitive and planned');
select ok(not has_schema_privilege('anon', 'platform', 'usage') and not has_schema_privilege('authenticated', 'platform', 'usage'), 'customers have no access to the platform schema');
select ok(not has_table_privilege('authenticated', 'platform.solutions', 'select'), 'signed-in users cannot read platform tables directly');
select is_empty($$ select c.relname from pg_class c where c.relnamespace = 'platform'::regnamespace and c.relkind = 'r' and not c.relrowsecurity $$, 'every platform table has row level security');
select is_empty($$ select c.relname from pg_class c join pg_attribute a on a.attrelid = c.oid and a.attname = 'business_id' and not a.attisdropped where c.relnamespace = 'platform'::regnamespace and c.relkind = 'r' $$, 'no platform table carries a business_id (platform tables are global)');
select is_empty($$ select c.relname from pg_class c
  where c.relnamespace = 'public'::regnamespace and c.relkind = 'r' and c.relname not in ('profiles', 'businesses', 'contact_messages')
    and not exists (select 1 from pg_attribute a where a.attrelid = c.oid and a.attname = 'business_id' and not a.attisdropped) $$, 'every business-owned table has a business_id');

-- behaviour
select t.as_user('a0000000-0000-0000-0000-00000000000a');
insert into t.r select 'a_biz', public.create_business('A Stores', 'retail', 'Kano', '2-5')::text;
select t.as_admin();
select t.as_user('b0000000-0000-0000-0000-00000000000b');
insert into t.r select 'b_biz', public.create_business('B Foods', 'food', 'Lagos', 'solo')::text;
select t.as_admin();

select t.as_user('a0000000-0000-0000-0000-00000000000a');
insert into t.r select 'a_list', count(*)::text from public.list_solutions();
insert into t.r select 'a_enable_super', t.try(format($q$select public.enable_solution(%L, 'supermarket')$q$, (select v from t.r where k = 'a_biz')));
insert into t.r select 'a_enable_school', t.try(format($q$select public.enable_solution(%L, 'school')$q$, (select v from t.r where k = 'a_biz')));
insert into t.r select 'a_enable_pharmacy', t.try(format($q$select public.enable_solution(%L, 'pharmacy')$q$, (select v from t.r where k = 'a_biz')));
insert into t.r select 'a_enable_unknown', t.try(format($q$select public.enable_solution(%L, 'nonsense')$q$, (select v from t.r where k = 'a_biz')));
insert into t.r select 'a_enable_on_b', t.try(format($q$select public.enable_solution(%L, 'supermarket')$q$, (select v from t.r where k = 'b_biz')));
insert into t.r select 'a_rows', count(*)::text from public.business_solutions;
insert into t.r select 'a_has_own', public.has_solution((select v from t.r where k = 'a_biz')::uuid, 'supermarket')::text;
select t.as_admin();

select t.as_user('b0000000-0000-0000-0000-00000000000b');
insert into t.r select 'b_rows', count(*)::text from public.business_solutions;
insert into t.r select 'b_has_a', public.has_solution((select v from t.r where k = 'a_biz')::uuid, 'supermarket')::text;
insert into t.r select 'b_direct_insert', t.try(format($q$insert into public.business_solutions (business_id, solution_key) values (%L, 'supermarket')$q$, (select v from t.r where k = 'b_biz')));
insert into t.r select 'b_disable_a', t.try(format($q$select public.disable_solution(%L, 'supermarket')$q$, (select v from t.r where k = 'a_biz')));
select t.as_admin();

select t.as_user('a0000000-0000-0000-0000-00000000000a');
insert into t.r select 'a_disable', t.try(format($q$select public.disable_solution(%L, 'supermarket')$q$, (select v from t.r where k = 'a_biz')));
insert into t.r select 'a_has_after_disable', public.has_solution((select v from t.r where k = 'a_biz')::uuid, 'supermarket')::text;
select t.as_admin();

select t.as_anon();
insert into t.r select 'anon_list', t.try('select count(*) from public.list_solutions()');
insert into t.r select 'anon_enable', t.try(format($q$select public.enable_solution(%L, 'supermarket')$q$, (select v from t.r where k = 'a_biz')));
insert into t.r select 'anon_read_rows', t.try('select count(*) from public.business_solutions');
select t.as_admin();

select is((select v from t.r where k = 'a_list'), '7', 'a signed-in user can list the seven solutions');
select is((select v from t.r where k = 'a_enable_super'), 'ok', 'an owner can enable an available standard solution');
select is((select v from t.r where k = 'a_enable_school'), '22023', 'a sensitive solution cannot be enabled');
select is((select v from t.r where k = 'a_enable_pharmacy'), '22023', 'a planned solution cannot be enabled');
select is((select v from t.r where k = 'a_enable_unknown'), '22023', 'an unknown solution is rejected');
select is((select v from t.r where k = 'a_enable_on_b'), '42501', 'A cannot change the solutions of B''s business');
select is((select v from t.r where k = 'a_rows'), '1', 'A sees exactly one solution row');
select is((select v from t.r where k = 'a_has_own'), 'true', 'has_solution is true for the owner of the business');
select is((select v from t.r where k = 'b_rows'), '0', 'B sees none of A''s solution rows');
select is((select v from t.r where k = 'b_has_a'), 'false', 'has_solution is false for someone who is not a member');
select is((select v from t.r where k = 'b_direct_insert'), '42501', 'B cannot write the registry directly');
select is((select v from t.r where k = 'b_disable_a'), '42501', 'B cannot disable A''s solution');
select is((select v from t.r where k = 'a_disable'), 'ok', 'the owner can disable a solution');
select is((select v from t.r where k = 'a_has_after_disable'), 'false', 'a disabled solution is no longer active');
select is((select v from t.r where k = 'anon_list'), '42501', 'anonymous visitors cannot list solutions');
select is((select v from t.r where k = 'anon_enable'), '42501', 'anonymous visitors cannot enable solutions');
select is((select v from t.r where k = 'anon_read_rows'), '42501', 'anonymous visitors cannot read the registry');

select * from finish();
rollback;
