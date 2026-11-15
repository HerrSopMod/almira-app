-- Foto de perfil del vecino. Un archivo por cuenta, en un bucket privado: {user_id}/perfil.jpg.
-- Cada persona solo ve y cambia el suyo (la carpeta es su user_id). Se muestra con una dirección
-- firmada temporal, como las fotos de los reclamos.
--
-- No es una tabla: no hay municipalidad_id ni columnas nuevas. La ruta no lleva datos personales.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatares', 'avatares', false, 2097152, array['image/jpeg', 'image/png', 'image/webp']);

create policy "avatar: ver el propio" on storage.objects
  for select to authenticated
  using (bucket_id = 'avatares' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "avatar: subir el propio" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatares' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "avatar: cambiar el propio" on storage.objects
  for update to authenticated
  using (bucket_id = 'avatares' and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (bucket_id = 'avatares' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "avatar: quitar el propio" on storage.objects
  for delete to authenticated
  using (bucket_id = 'avatares' and (storage.foldername(name))[1] = (select auth.uid())::text);
