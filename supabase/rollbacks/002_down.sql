-- ROLLBACK for 002_contact_rate_limit.sql (removes the spam limit only; messages are kept)
drop trigger if exists contact_messages_rate_limit on public.contact_messages;
drop function if exists public.contact_messages_rate_limit();
drop index if exists public.contact_messages_created_at_idx;
drop index if exists public.contact_messages_email_created_idx;
