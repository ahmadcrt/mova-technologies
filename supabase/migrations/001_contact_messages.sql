-- MOVA website: contact form storage.
-- Anonymous visitors may INSERT only. They cannot read, update or delete anything.
-- Run in the Supabase SQL editor (or via the Supabase CLI). Review before applying to production.

create table if not exists public.contact_messages (
  id          uuid primary key default gen_random_uuid(),
  created_at  timestamptz not null default now(),
  name        text not null check (char_length(name) between 1 and 120),
  email       text not null check (char_length(email) between 5 and 254 and email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  topic       text not null check (topic in ('general', 'early-access', 'custom-project', 'partnership')),
  message     text not null check (char_length(message) between 10 and 2000),
  consent     boolean not null check (consent = true)
);

alter table public.contact_messages enable row level security;

revoke all on public.contact_messages from anon, authenticated;
grant insert on public.contact_messages to anon;

drop policy if exists "anon can insert contact messages" on public.contact_messages;
create policy "anon can insert contact messages"
  on public.contact_messages for insert to anon
  with check (true);

-- No select/update/delete policy exists, so messages can only be read by the project owner
-- in the Supabase dashboard (or with the secret key on a server). Never expose that key in the website.
