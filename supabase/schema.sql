-- Luck'In : base de données Supabase
-- À coller en une fois dans Supabase › SQL Editor › New query, puis « Run ».

-- 1. Profils (prénom visible par les membres de ton groupe)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null default '',
  created_at timestamptz not null default now()
);

-- 2. Données privées de l'app (journal complet, visible uniquement par son propriétaire)
create table if not exists public.user_data (
  user_id uuid primary key references auth.users(id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

-- 3. Groupes d'amis rejoints par code d'invitation
create table if not exists public.groups (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null default 'Mon groupe',
  owner uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.group_members (
  group_id uuid not null references public.groups(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

-- 4. Ce qui est partagé avec le groupe : régularité du jour et progression en %
--    (jamais le poids, les repas ni les mesures)
create table if not exists public.daily_share (
  user_id uuid not null references auth.users(id) on delete cascade,
  day date not null,
  morning boolean not null default false,
  evening boolean not null default false,
  session boolean not null default false,
  progress numeric,            -- 0 à 100, avancement vers l'objectif
  updated_at timestamptz not null default now(),
  primary key (user_id, day)
);

-- Fonction utilitaire : deux personnes partagent-elles un groupe ?
create or replace function public.is_groupmate(other uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from group_members a join group_members b on a.group_id = b.group_id
    where a.user_id = auth.uid() and b.user_id = other
  );
$$;

-- Rejoindre un groupe avec son code (sans pouvoir lister les autres groupes)
create or replace function public.join_group(invite text)
returns uuid language plpgsql security definer set search_path = public as $$
declare g uuid;
begin
  select id into g from groups where code = upper(trim(invite));
  if g is null then raise exception 'Code invalide'; end if;
  insert into group_members(group_id, user_id) values (g, auth.uid()) on conflict do nothing;
  return g;
end $$;

-- Sécurité : chaque table est verrouillée, puis on ouvre le strict nécessaire
alter table public.profiles      enable row level security;
alter table public.user_data     enable row level security;
alter table public.groups        enable row level security;
alter table public.group_members enable row level security;
alter table public.daily_share   enable row level security;

create policy "profil: lire soi ou ses amis" on public.profiles for select
  using (id = auth.uid() or public.is_groupmate(id));
create policy "profil: créer le sien" on public.profiles for insert with check (id = auth.uid());
create policy "profil: modifier le sien" on public.profiles for update using (id = auth.uid());

create policy "données: tout sur les siennes uniquement" on public.user_data for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "groupe: lire ceux dont on est membre" on public.groups for select
  using (owner = auth.uid() or exists (select 1 from group_members m where m.group_id = id and m.user_id = auth.uid()));
create policy "groupe: créer" on public.groups for insert with check (owner = auth.uid());
create policy "groupe: le créateur modifie ou supprime" on public.groups for update using (owner = auth.uid());
create policy "groupe: le créateur supprime" on public.groups for delete using (owner = auth.uid());

create policy "membres: voir ceux de ses groupes" on public.group_members for select
  using (user_id = auth.uid() or public.is_groupmate(user_id));
create policy "membres: s'ajouter soi-même" on public.group_members for insert with check (user_id = auth.uid());
create policy "membres: quitter" on public.group_members for delete using (user_id = auth.uid());

create policy "partage: lire soi ou ses amis" on public.daily_share for select
  using (user_id = auth.uid() or public.is_groupmate(user_id));
create policy "partage: écrire le sien" on public.daily_share for insert with check (user_id = auth.uid());
create policy "partage: modifier le sien" on public.daily_share for update using (user_id = auth.uid());
create policy "partage: supprimer le sien" on public.daily_share for delete using (user_id = auth.uid());

-- Suppression de compte depuis l'app (efface aussi toutes les données liées)
create or replace function public.delete_me()
returns void language plpgsql security definer set search_path = public, auth as $$
begin
  delete from auth.users where id = auth.uid();
end $$;

grant execute on function public.join_group(text) to authenticated;
grant execute on function public.delete_me() to authenticated;
grant execute on function public.is_groupmate(uuid) to authenticated;
