-- Luck'In : partage de l'agenda avec un ami du même groupe.
-- À coller une fois dans Supabase › SQL Editor › Run.
-- Une ligne par (propriétaire, ami) : les créneaux des 14 prochains jours, déjà filtrés selon le niveau choisi.
-- Niveau « busy » : seulement les heures (aucun titre n'est envoyé) ; « full » : heures + titres.
create table if not exists public.agenda_share (
  owner uuid not null references auth.users on delete cascade,
  viewer uuid not null references auth.users on delete cascade,
  level text not null check (level in ('busy', 'full')),
  blocks jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (owner, viewer)
);
alter table public.agenda_share enable row level security;
drop policy if exists "agenda: le propriétaire gère" on public.agenda_share;
drop policy if exists "agenda: l'ami lit" on public.agenda_share;
-- seul le propriétaire écrit, et seulement pour un membre de son groupe
create policy "agenda: le propriétaire gère" on public.agenda_share for all
  using (owner = auth.uid()) with check (owner = auth.uid() and public.is_groupmate(viewer));
-- l'ami ne lit que ce qui lui est destiné
create policy "agenda: l'ami lit" on public.agenda_share for select using (viewer = auth.uid());
