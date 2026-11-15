-- ROLLBACK for 001_contact_messages.sql
-- DANGER: deletes every stored contact message. Export them first.
drop table if exists public.contact_messages cascade;
