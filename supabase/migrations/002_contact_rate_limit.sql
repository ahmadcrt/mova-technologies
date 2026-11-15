-- MOVA website: server-side spam protection for the contact form.
-- Run AFTER 001_contact_messages.sql, in the Supabase SQL editor.
-- Limits: at most 3 messages per email address per hour, and at most 60 messages in total per hour.
-- Over the limit, the insert is rejected with HTTP 429 (PostgREST maps the PT429 error code to 429).

create index if not exists contact_messages_created_at_idx on public.contact_messages (created_at);
create index if not exists contact_messages_email_created_idx on public.contact_messages (lower(email), created_at);

create or replace function public.contact_messages_rate_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  same_email integer;
  total_recent integer;
begin
  select count(*) into same_email
  from public.contact_messages
  where lower(email) = lower(new.email) and created_at > now() - interval '1 hour';
  if same_email >= 3 then
    raise exception 'Too many messages from this email address' using errcode = 'PT429';
  end if;

  select count(*) into total_recent
  from public.contact_messages
  where created_at > now() - interval '1 hour';
  if total_recent >= 60 then
    raise exception 'Too many messages right now' using errcode = 'PT429';
  end if;

  return new;
end;
$$;

revoke all on function public.contact_messages_rate_limit() from public, anon, authenticated;

drop trigger if exists contact_messages_rate_limit on public.contact_messages;
create trigger contact_messages_rate_limit
  before insert on public.contact_messages
  for each row execute function public.contact_messages_rate_limit();
