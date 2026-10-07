-- Luck'In · Apprentissage (deuxième cerveau) : espace privé pour les photos, audios et petites vidéos.
-- À coller une fois dans Supabase › SQL Editor › New query, puis « Run ».
-- Chaque utilisateur ne voit et ne modifie que son propre dossier (nommé avec son identifiant).

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('brain', 'brain', false, 52428800, array['image/*', 'audio/*', 'video/*'])
on conflict (id) do update set public = false, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "brain: lire ses fichiers" on storage.objects;
drop policy if exists "brain: ajouter ses fichiers" on storage.objects;
drop policy if exists "brain: modifier ses fichiers" on storage.objects;
drop policy if exists "brain: supprimer ses fichiers" on storage.objects;

create policy "brain: lire ses fichiers" on storage.objects for select to authenticated
  using (bucket_id = 'brain' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "brain: ajouter ses fichiers" on storage.objects for insert to authenticated
  with check (bucket_id = 'brain' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "brain: modifier ses fichiers" on storage.objects for update to authenticated
  using (bucket_id = 'brain' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "brain: supprimer ses fichiers" on storage.objects for delete to authenticated
  using (bucket_id = 'brain' and (storage.foldername(name))[1] = auth.uid()::text);
