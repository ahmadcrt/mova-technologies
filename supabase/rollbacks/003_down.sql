-- ROLLBACK for 003_platform_foundation.sql
-- DANGER: deletes all profiles, businesses and memberships. Sign-in accounts (auth.users) are NOT deleted.
-- Export these tables first.
drop function if exists public.create_business(text, text, text, text);
drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user();
drop table if exists public.business_members cascade;
drop table if exists public.businesses cascade;
drop table if exists public.profiles cascade;
drop function if exists public.is_member(uuid);
drop function if exists public.has_role(uuid, text[]);
drop function if exists public.set_updated_at();
