-- ROLLBACK for 004_solutions_registry.sql
-- DANGER: removes the registry and every business's solution choices. Existing businesses, members and profiles are NOT touched.
drop function if exists public.disable_solution(uuid, text);
drop function if exists public.enable_solution(uuid, text);
drop function if exists public.list_solutions();
drop function if exists public.has_solution(uuid, text);
drop table if exists public.business_solutions cascade;
drop table if exists platform.solutions cascade;
drop schema if exists platform;
