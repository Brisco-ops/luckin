-- Luck'In : dépenses Apple Pay envoyées par un raccourci iPhone (automatisation « Transaction »).
-- À coller une fois dans Supabase › SQL Editor › Run.
-- pay_tokens : empreinte (SHA-256) du code personnel que le raccourci envoie ; le code lui-même n'est jamais stocké.
create table if not exists public.pay_tokens (
  user_id uuid primary key references auth.users on delete cascade,
  token_hash text not null unique,
  created_at timestamptz not null default now()
);
alter table public.pay_tokens enable row level security;
drop policy if exists "pay_tokens own" on public.pay_tokens;
create policy "pay_tokens own" on public.pay_tokens for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- pay_inbox : paiements reçus, en attente que l'app les range dans le budget (puis elle les efface).
-- Seule la fonction « push » (clé serveur) y écrit ; l'utilisateur ne peut que lire et effacer les siens.
create table if not exists public.pay_inbox (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  amount numeric not null,
  merchant text,
  card text,
  at timestamptz not null default now()
);
alter table public.pay_inbox enable row level security;
drop policy if exists "pay_inbox read own" on public.pay_inbox;
drop policy if exists "pay_inbox delete own" on public.pay_inbox;
create policy "pay_inbox read own" on public.pay_inbox for select using (auth.uid() = user_id);
create policy "pay_inbox delete own" on public.pay_inbox for delete using (auth.uid() = user_id);
create index if not exists pay_inbox_user on public.pay_inbox (user_id, at);
