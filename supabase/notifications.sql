-- Luck'In · notifications (1/2) : à coller dans Supabase › SQL Editor › New query, puis « Run ».

-- Appareils abonnés aux notifications (un par téléphone)
create table if not exists public.push_subs (
  endpoint text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  p256dh text not null,
  auth text not null,
  tz text not null default 'Europe/Paris',
  prefs jsonb not null default '{}'::jsonb,      -- { on, morning, evening, weekly } : heures des rappels
  last_sent jsonb not null default '{}'::jsonb,  -- évite d'envoyer deux fois le même rappel
  created_at timestamptz not null default now()
);
alter table public.push_subs enable row level security;
create policy "push: gérer ses appareils" on public.push_subs for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Encouragements entre amis (un par jour et par ami, écrits uniquement par le serveur)
create table if not exists public.cheers (
  from_id uuid not null references auth.users(id) on delete cascade,
  to_id uuid not null references auth.users(id) on delete cascade,
  day date not null,
  created_at timestamptz not null default now(),
  primary key (from_id, to_id, day)
);
alter table public.cheers enable row level security;
create policy "encouragements: voir ceux reçus ou envoyés" on public.cheers for select
  using (to_id = auth.uid() or from_id = auth.uid());

-- Planificateur (remplacer <CRON_SECRET> par la valeur du secret CRON_SECRET de Supabase avant d'exécuter ; ne jamais committer la vraie valeur) : appelle la fonction « push » toutes les 15 minutes
create extension if not exists pg_cron;
create extension if not exists pg_net;
select cron.schedule('luckin-rappels', '*/15 * * * *', $$
  select net.http_post(
    url := 'https://uuekwjieeswcipzkucjb.supabase.co/functions/v1/push',
    headers := '{"Content-Type":"application/json","apikey":"sb_publishable_f8pBWkJT7N1jF7Sk6MEHtA_muuheuqS","x-cron-secret":"<CRON_SECRET>"}'::jsonb,
    body := '{"kind":"cron"}'::jsonb
  );
$$);
