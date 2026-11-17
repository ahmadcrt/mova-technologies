-- Tests for stage S2 (migration 005): timezone, currency, business_type rule. Rolled back at the end.
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
 ('b0000000-0000-0000-0000-00000000000b', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'b@test.local', '', now(), '{}', '{"full_name":"User B"}', now(), now()),
 ('c0000000-0000-0000-0000-00000000000c', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'c@test.local', '', now(), '{}', '{"full_name":"User C"}', now(), now());

select t.as_user('a0000000-0000-0000-0000-00000000000a');
insert into t.r select 'a_biz', public.create_business('A Stores', 'retail', 'Kano', '2-5')::text;
select t.as_admin();
select t.as_user('b0000000-0000-0000-0000-00000000000b');
insert into t.r select 'b_biz', public.create_business('B Foods', 'food', 'Lagos', 'solo')::text;
select t.as_admin();

select is((select timezone from public.businesses where id = (select v from t.r where k = 'a_biz')::uuid), 'Africa/Lagos', 'a new business defaults to the Lagos timezone');
select is((select currency from public.businesses where id = (select v from t.r where k = 'a_biz')::uuid), 'NGN', 'a new business defaults to naira');

select t.as_user('a0000000-0000-0000-0000-00000000000a');
insert into t.r select 'a_tz_ok', t.try(format($q$update public.businesses set timezone = 'Africa/Accra' where id = %L$q$, (select v from t.r where k = 'a_biz')));
insert into t.r select 'a_tz_bad', t.try(format($q$update public.businesses set timezone = 'Mars/Phobos' where id = %L$q$, (select v from t.r where k = 'a_biz')));
insert into t.r select 'a_cur_ok', t.try(format($q$update public.businesses set currency = 'GHS' where id = %L$q$, (select v from t.r where k = 'a_biz')));
insert into t.r select 'a_cur_bad', t.try(format($q$update public.businesses set currency = 'naira' where id = %L$q$, (select v from t.r where k = 'a_biz')));
insert into t.r select 'a_type_ok', t.try(format($q$update public.businesses set business_type = 'bakery' where id = %L$q$, (select v from t.r where k = 'a_biz')));
insert into t.r select 'a_type_bad', t.try(format($q$update public.businesses set business_type = 'Bad Type!' where id = %L$q$, (select v from t.r where k = 'a_biz')));
insert into t.r select 'a_type_null', t.try(format($q$update public.businesses set business_type = null where id = %L$q$, (select v from t.r where k = 'a_biz')));
select t.as_admin();

select t.as_user('b0000000-0000-0000-0000-00000000000b');
update public.businesses set timezone = 'Africa/Cairo' where id = (select v from t.r where k = 'a_biz')::uuid;
select t.as_admin();

select t.as_user('c0000000-0000-0000-0000-00000000000c');
insert into t.r select 'c_old_type', t.try($q$select public.create_business('C Shop', 'bakery', null, null)$q$);
select t.as_admin();

select t.as_anon();
insert into t.r select 'anon_update', t.try(format($q$update public.businesses set timezone = 'Africa/Cairo' where id = %L$q$, (select v from t.r where k = 'a_biz')));
select t.as_admin();

select is((select v from t.r where k = 'a_tz_ok'), 'ok', 'the owner can change the timezone');
select is((select v from t.r where k = 'a_tz_bad'), '22023', 'an unknown timezone is rejected');
select is((select v from t.r where k = 'a_cur_ok'), 'ok', 'the owner can change the currency code');
select is((select v from t.r where k = 'a_cur_bad'), '23514', 'an invalid currency code is rejected');
select is((select v from t.r where k = 'a_type_ok'), 'ok', 'a new business type value is accepted');
select is((select v from t.r where k = 'a_type_bad'), '23514', 'a badly formed business type is rejected');
select is((select v from t.r where k = 'a_type_null'), 'ok', 'business type can be empty');
select is((select timezone from public.businesses where id = (select v from t.r where k = 'a_biz')::uuid), 'Africa/Accra', 'B cannot change the timezone of A''s business');
select is((select v from t.r where k = 'c_old_type'), '22023', 'create_business still checks its own type list (it changes in stage S5)');
select is((select v from t.r where k = 'anon_update'), '42501', 'anonymous visitors cannot update businesses');

select * from finish();
rollback;
