-- Run in the Supabase SQL editor after 005_business_profile_settings.sql. Every row must show true.
select 'timezone_column_exists' as check_name, exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'businesses' and column_name = 'timezone') as passed
union all select 'currency_column_exists', exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'businesses' and column_name = 'currency')
union all select 'business_type_can_be_empty', (select is_nullable = 'YES' from information_schema.columns where table_schema = 'public' and table_name = 'businesses' and column_name = 'business_type')
union all select 'existing_businesses_have_defaults', not exists (select 1 from public.businesses where timezone <> 'Africa/Lagos' or currency <> 'NGN')
union all select 'no_business_lost', (select count(*) >= 1 from public.businesses);
