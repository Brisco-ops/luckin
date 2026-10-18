-- Luck'In : « Tu dors ? » le soir (heure d'endormissement pour calculer la durée du sommeil).
-- À coller une fois dans Supabase › SQL Editor › Run.
-- Une ligne par utilisateur et par nuit : dernière question envoyée, dernière réponse « encore debout », heure d'endormissement retenue.
create table if not exists public.sleep_probe (
  user_id uuid primary key references auth.users on delete cascade,
  night date not null,
  last_probe timestamptz,
  last_answer timestamptz,
  asleep_at timestamptz
);
alter table public.sleep_probe enable row level security;
drop policy if exists "sommeil: le sien" on public.sleep_probe;
create policy "sommeil: le sien" on public.sleep_probe for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
