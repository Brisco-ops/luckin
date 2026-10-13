-- Luck'In : historique automatique du journal (protection contre un écrasement accidentel).
-- À coller une fois dans Supabase › SQL Editor › Run.
-- À chaque synchro qui change le journal, l'ancienne version est copiée ici (au plus une copie par quart d'heure).
-- On garde : tout ce qui a moins de 2 jours, puis une version par jour pendant 90 jours.
create table if not exists public.user_data_history (
  id bigserial primary key,
  user_id uuid not null references auth.users on delete cascade,
  data jsonb not null,
  saved_at timestamptz not null default now()
);
create index if not exists user_data_history_user on public.user_data_history (user_id, saved_at desc);
alter table public.user_data_history enable row level security;
drop policy if exists "history read own" on public.user_data_history;
drop policy if exists "history insert own" on public.user_data_history;
create policy "history read own" on public.user_data_history for select using (auth.uid() = user_id);
-- l'app ajoute elle-même une copie juste avant une restauration
create policy "history insert own" on public.user_data_history for insert with check (auth.uid() = user_id);

create or replace function public.keep_user_data_history() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if old.data is distinct from new.data
     and not exists (select 1 from user_data_history where user_id = old.user_id and saved_at > now() - interval '15 minutes') then
    insert into user_data_history (user_id, data) values (old.user_id, old.data);
    delete from user_data_history h
     where h.user_id = old.user_id
       and (h.saved_at < now() - interval '90 days'
            or (h.saved_at < now() - interval '2 days'
                and exists (select 1 from user_data_history h2
                             where h2.user_id = h.user_id
                               and h2.saved_at::date = h.saved_at::date
                               and h2.saved_at > h.saved_at)));
  end if;
  return new;
end $$;

drop trigger if exists user_data_history_trg on public.user_data;
create trigger user_data_history_trg before update on public.user_data
  for each row execute function public.keep_user_data_history();
