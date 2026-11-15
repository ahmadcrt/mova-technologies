-- Baseline security tests for the current schema. Every check must pass before any migration is used in production.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

select is_empty(
  $$ select c.relname from pg_class c
     where c.relnamespace = 'public'::regnamespace and c.relkind = 'r' and not c.relrowsecurity $$,
  'every table in the public schema has row level security enabled');

select is_empty(
  $$ select c.conrelid::regclass::text, c.conname from pg_constraint c
     where c.contype = 'f'
       and c.connamespace = 'public'::regnamespace
       and (select relnamespace from pg_class where oid = c.confrelid) = 'public'::regnamespace
       and exists (select 1 from pg_attribute a where a.attrelid = c.conrelid and a.attname = 'business_id' and not a.attisdropped)
       and not exists (select 1 from pg_attribute a where a.attrelid = c.conrelid and a.attnum = any (c.conkey) and a.attname = 'business_id') $$,
  'every foreign key between business-owned tables includes business_id');

select is_empty(
  $$ select c.relname from pg_class c
     where c.relnamespace = 'public'::regnamespace and c.relkind = 'r' and c.relname <> 'contact_messages'
       and (has_table_privilege('anon', c.oid, 'select') or has_table_privilege('anon', c.oid, 'insert')
            or has_table_privilege('anon', c.oid, 'update') or has_table_privilege('anon', c.oid, 'delete')) $$,
  'anonymous visitors have no access to any table except contact_messages');

select ok(
  has_table_privilege('anon', 'public.contact_messages', 'insert')
  and not has_table_privilege('anon', 'public.contact_messages', 'select')
  and not has_table_privilege('anon', 'public.contact_messages', 'update')
  and not has_table_privilege('anon', 'public.contact_messages', 'delete'),
  'anonymous visitors can only insert into contact_messages');

select is_empty(
  $$ select p.proname from pg_proc p
     where p.pronamespace = 'public'::regnamespace and p.prosecdef and has_function_privilege('anon', p.oid, 'execute') $$,
  'no security definer function can be called by anonymous visitors');

select is_empty(
  $$ select p.proname from pg_proc p
     where p.pronamespace = 'public'::regnamespace and p.prosecdef
       and (p.proconfig is null or not exists (select 1 from unnest(p.proconfig) cfg where cfg like 'search_path=%')) $$,
  'every security definer function pins its search_path');

select * from finish();
rollback;
