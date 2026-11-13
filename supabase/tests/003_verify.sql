-- Run after 003_platform_foundation.sql. Every row must show true.
select 'rls_profiles' as check_name, relrowsecurity as passed from pg_class where oid = 'public.profiles'::regclass
union all select 'rls_businesses', relrowsecurity from pg_class where oid = 'public.businesses'::regclass
union all select 'rls_business_members', relrowsecurity from pg_class where oid = 'public.business_members'::regclass
union all select 'anon_cannot_call_create_business', not has_function_privilege('anon', 'public.create_business(text,text,text,text)', 'execute')
union all select 'signed_in_can_call_create_business', has_function_privilege('authenticated', 'public.create_business(text,text,text,text)', 'execute')
union all select 'anon_cannot_read_profiles', not has_table_privilege('anon', 'public.profiles', 'select')
union all select 'anon_cannot_read_businesses', not has_table_privilege('anon', 'public.businesses', 'select')
union all select 'anon_cannot_read_members', not has_table_privilege('anon', 'public.business_members', 'select')
union all select 'signed_in_cannot_insert_business_directly', not has_table_privilege('authenticated', 'public.businesses', 'insert')
union all select 'signed_in_cannot_delete_business', not has_table_privilege('authenticated', 'public.businesses', 'delete')
union all select 'signed_in_cannot_change_members', not (has_table_privilege('authenticated', 'public.business_members', 'insert') or has_table_privilege('authenticated', 'public.business_members', 'update') or has_table_privilege('authenticated', 'public.business_members', 'delete'));
