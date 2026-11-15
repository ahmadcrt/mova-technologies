-- Cross-business isolation tests for the current schema (migrations 001 to 003).
-- Three test users: A (owns a business), B (owns another), C (no business). Everything is rolled back.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

-- helpers (rolled back with the transaction)
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

select is((select count(*)::int from public.profiles where id in ('a0000000-0000-0000-0000-00000000000a', 'b0000000-0000-0000-0000-00000000000b', 'c0000000-0000-0000-0000-00000000000c')), 3, 'a profile is created for every new user');

-- user A
select t.as_user('a0000000-0000-0000-0000-00000000000a');
insert into t.r select 'a_biz', public.create_business('A Stores', 'retail', 'Kano', '2-5')::text;
insert into t.r select 'a_biz_count', count(*)::text from public.businesses;
insert into t.r select 'a_mem_count', count(*)::text from public.business_members;
insert into t.r select 'a_profiles', count(*)::text from public.profiles;
insert into t.r select 'a_second', t.try($q$select public.create_business('Second', 'retail', null, null)$q$);
select t.as_admin();

-- user B
select t.as_user('b0000000-0000-0000-0000-00000000000b');
insert into t.r select 'b_biz', public.create_business('B Foods', 'food', 'Lagos', 'solo')::text;
insert into t.r select 'b_biz_count', count(*)::text from public.businesses;
insert into t.r select 'b_biz_name', name from public.businesses limit 1;
insert into t.r select 'b_mem_count', count(*)::text from public.business_members;
insert into t.r select 'b_add_member', t.try(format($q$insert into public.business_members (business_id, user_id, role) values (%L, 'b0000000-0000-0000-0000-00000000000b', 'owner')$q$, (select v from t.r where k = 'a_biz')));
insert into t.r select 'b_insert_biz', t.try($q$insert into public.businesses (owner_id, name, business_type) values ('b0000000-0000-0000-0000-00000000000b', 'X', 'retail')$q$);
insert into t.r select 'b_delete_biz', t.try(format($q$delete from public.businesses where id = %L$q$, (select v from t.r where k = 'a_biz')));
insert into t.r select 'b_change_owner', t.try(format($q$update public.businesses set owner_id = 'b0000000-0000-0000-0000-00000000000b' where id = %L$q$, (select v from t.r where k = 'b_biz')));
update public.businesses set name = 'hacked' where id = (select v from t.r where k = 'a_biz')::uuid;
select t.as_admin();

-- user C (no business)
select t.as_user('c0000000-0000-0000-0000-00000000000c');
insert into t.r select 'c_biz_count', count(*)::text from public.businesses;
insert into t.r select 'c_mem_count', count(*)::text from public.business_members;
insert into t.r select 'c_profiles', count(*)::text from public.profiles;
select t.as_admin();

-- anonymous visitor
select t.as_anon();
insert into t.r select 'anon_read_biz', t.try('select count(*) from public.businesses');
insert into t.r select 'anon_create_biz', t.try($q$select public.create_business('Z', 'retail', null, null)$q$);
insert into t.r select 'contact_1', t.try($q$insert into public.contact_messages (name, email, topic, message, consent) values ('T', 'c1@test.local', 'general', 'Hello this is a test', true)$q$);
insert into t.r select 'contact_read', t.try('select count(*) from public.contact_messages');
insert into t.r select 'contact_bad_topic', t.try($q$insert into public.contact_messages (name, email, topic, message, consent) values ('T', 'c2@test.local', 'nonsense', 'Hello this is a test', true)$q$);
insert into t.r select 'contact_no_consent', t.try($q$insert into public.contact_messages (name, email, topic, message, consent) values ('T', 'c3@test.local', 'general', 'Hello this is a test', false)$q$);
insert into t.r select 'contact_2', t.try($q$insert into public.contact_messages (name, email, topic, message, consent) values ('T', 'c1@test.local', 'general', 'Hello this is a test', true)$q$);
insert into t.r select 'contact_3', t.try($q$insert into public.contact_messages (name, email, topic, message, consent) values ('T', 'c1@test.local', 'general', 'Hello this is a test', true)$q$);
insert into t.r select 'contact_4', t.try($q$insert into public.contact_messages (name, email, topic, message, consent) values ('T', 'c1@test.local', 'general', 'Hello this is a test', true)$q$);
select t.as_admin();

select is((select v from t.r where k = 'a_biz_count'), '1', 'A sees exactly one business');
select is((select v from t.r where k = 'a_mem_count'), '1', 'A sees exactly one membership');
select is((select v from t.r where k = 'a_profiles'), '1', 'A sees only their own profile');
select is((select v from t.r where k = 'a_second'), '23505', 'A cannot create a second business (current rule; changes in stage S5)');
select is((select v from t.r where k = 'b_biz_count'), '1', 'B sees exactly one business');
select is((select v from t.r where k = 'b_biz_name'), 'B Foods', 'B sees only their own business');
select is((select v from t.r where k = 'b_mem_count'), '1', 'B sees exactly one membership');
select is((select v from t.r where k = 'b_add_member'), '42501', 'B cannot add themselves to another business');
select is((select v from t.r where k = 'b_insert_biz'), '42501', 'B cannot insert a business directly');
select is((select v from t.r where k = 'b_delete_biz'), '42501', 'B cannot delete a business');
select is((select v from t.r where k = 'b_change_owner'), '42501', 'B cannot change the owner of a business');
select is((select name from public.businesses where id = (select v from t.r where k = 'a_biz')::uuid), 'A Stores', 'B cannot rename the business of A');
select is((select v from t.r where k = 'c_biz_count'), '0', 'a user with no business sees no businesses');
select is((select v from t.r where k = 'c_mem_count'), '0', 'a user with no business sees no memberships');
select is((select v from t.r where k = 'c_profiles'), '1', 'a user with no business sees only their own profile');
select is((select v from t.r where k = 'anon_read_biz'), '42501', 'anonymous visitors cannot read businesses');
select is((select v from t.r where k = 'anon_create_biz'), '42501', 'anonymous visitors cannot create businesses');
select is((select v from t.r where k = 'contact_1'), 'ok', 'anonymous visitors can send a contact message');
select is((select v from t.r where k = 'contact_read'), '42501', 'anonymous visitors cannot read contact messages');
select is((select v from t.r where k = 'contact_bad_topic'), '23514', 'an unknown contact topic is rejected');
select is((select v from t.r where k = 'contact_no_consent'), '23514', 'a contact message without consent is rejected');
select is((select v from t.r where k = 'contact_3'), 'ok', 'the third message from one email in an hour is accepted');
select is((select v from t.r where k = 'contact_4'), 'PT429', 'the fourth message from one email in an hour is refused (rate limit)');

select * from finish();
rollback;
