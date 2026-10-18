-- Luck'In : inviter un ami du groupe sur une tâche (« Théâtre le 23 avec Océane »).
-- À coller une fois dans Supabase › SQL Editor › Run.
-- Une ligne par (tâche, ami invité). L'ami la voit dans son planning et répond : je viens / je ne peux pas.
create table if not exists public.invites (
  id text primary key,                 -- <id de la tâche>:<id de l'ami>
  owner uuid not null references auth.users on delete cascade,
  viewer uuid not null references auth.users on delete cascade,
  item jsonb not null,                 -- titre, date, heure, durée, note
  status text not null default 'pending' check (status in ('pending', 'yes', 'no')),
  updated_at timestamptz not null default now()
);
create index if not exists invites_viewer on public.invites (viewer);
alter table public.invites enable row level security;
drop policy if exists "invitations: l'organisateur gère" on public.invites;
drop policy if exists "invitations: l'invité lit" on public.invites;
drop policy if exists "invitations: l'invité répond" on public.invites;
create policy "invitations: l'organisateur gère" on public.invites for all
  using (owner = auth.uid()) with check (owner = auth.uid() and public.is_groupmate(viewer));
create policy "invitations: l'invité lit" on public.invites for select using (viewer = auth.uid());
create policy "invitations: l'invité répond" on public.invites for update using (viewer = auth.uid()) with check (viewer = auth.uid());
